import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'pi_display_screen.dart';

class HostLoginScreen extends StatefulWidget {
  const HostLoginScreen({super.key});

  @override
  State<HostLoginScreen> createState() => _HostLoginScreenState();
}

class _HostLoginScreenState extends State<HostLoginScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithAdminCode(
      _codeController.text.trim(),
    );

    if (success && mounted) {
      // Check admin type
      if (authProvider.adminType == 'pi') {
        // Pi code is not allowed on this interface
        await authProvider.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pi codes cannot be used on this interface. Please use a tablet code.'),
            backgroundColor: Colors.red,
          ),
        );
        _codeController.clear();
      } else {
        // Tablet code - navigate to host dashboard
        Navigator.of(context).pushReplacementNamed('/host-dashboard');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  void _showPcodeMenu() {
    final pcodeController = TextEditingController();
    final firestore = FirebaseFirestore.instance;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Pi Code Access',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: pcodeController,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Enter Pi Code',
            labelStyle: const TextStyle(color: Colors.white70),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = pcodeController.text.trim();
              Navigator.pop(dialogContext);

              if (code.isNotEmpty) {
                try {
                  // Find which gym this pcode belongs to
                  final query = await firestore
                      .collection('coaches')
                      .where('pcode', isEqualTo: code)
                      .limit(1)
                      .get();

                  if (query.docs.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid Pi Code'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  final gymId = query.docs.first.data()['gymId'] as String?;

                  if (gymId == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gym not found for this code'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Navigate to isolated Pi Display screen
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PiDisplayScreen(gymId: gymId),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'Access Display',
              style: GoogleFonts.barlow(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // SPRTN STUDIO Logo - DO NOT EDIT
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
                // Host Login Title - Long press for 2 seconds to access Pi login
                GestureDetector(
                  onLongPress: _showPcodeMenu,
                  child: Text(
                    'Host Login',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _codeController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Admin Code',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter 6-8 character code',
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
                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
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
                          'Enter Gym',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
