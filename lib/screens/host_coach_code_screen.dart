import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class HostCoachCodeScreen extends StatefulWidget {
  const HostCoachCodeScreen({super.key});

  @override
  State<HostCoachCodeScreen> createState() => _HostCoachCodeScreenState();
}

class _HostCoachCodeScreenState extends State<HostCoachCodeScreen> {
  final _coachCodeController = TextEditingController();
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _coachCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final authProvider = context.read<AuthProvider>();
    final code = _coachCodeController.text.trim();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coach code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Query Firestore for a coach with this code
      final coachQuery = await _firestore
          .collection('coaches')
          .where('coachCode', isEqualTo: code)
          .limit(1)
          .get();

      if (coachQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coach code not found')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Verify the coach is in the same gym as the admin
      final selectedCoach = coachQuery.docs.first.data();
      final selectedCoachId = coachQuery.docs.first.id;
      final selectedCoachGymId = selectedCoach['gymId'] as String?;
      
      if (selectedCoachGymId != authProvider.currentGym?.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coach is not in your gym')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Store the selected coach ID and code
      authProvider.setHostCoachCode(selectedCoachId);
      
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/host-coach-workouts');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showPasswordVerification(BuildContext context) {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Enter Your Password',
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Required to access admin settings',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => isPasswordVisible = !isPasswordVisible);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.barlow(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
                onPressed: () async {
                  final password = passwordController.text;
                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your password')),
                    );
                    return;
                  }

                  // Verify password by attempting to re-authenticate
                  final authProvider = context.read<AuthProvider>();
                  try {
                    await authProvider.verifyAdminPassword(password);
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/host-settings');
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid password')),
                      );
                    }
                  }
                },
                child: Text(
                  'Verify',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showPasswordVerification(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            // Logo
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'STUDIO',
                    textScaleFactor: 1.0,
                    style: GoogleFonts.barlow(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Positioned(
                    left: 5,
                    top: -6,
                    child: Text(
                      'SPRTN',
                      textScaleFactor: 1.0,
                      style: GoogleFonts.barlow(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            Text(
              'Enter Coach Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _coachCodeController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Coach Code',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Enter your personal coach code',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.read<AuthProvider>().getGymPrimaryColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'View Workouts',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
