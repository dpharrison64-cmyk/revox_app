import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class GymCodeScreen extends StatefulWidget {
  const GymCodeScreen({super.key});

  @override
  State<GymCodeScreen> createState() => _GymCodeScreenState();
}

class _GymCodeScreenState extends State<GymCodeScreen> {
  final _gymCodeController = TextEditingController();

  @override
  void dispose() {
    _gymCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final authProvider = context.read<AuthProvider>();
    final code = _gymCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a gym code')),
      );
      return;
    }

    final isValid = await authProvider.validateGymCode(code);
    
    if (isValid && mounted) {
      authProvider.setGymCode(code);
      Navigator.of(context).pushReplacementNamed('/auth');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid gym code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80),
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
            const SizedBox(height: 100),
            Text(
              'Enter Gym Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _gymCodeController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Gym Code',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., ABC123',
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
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
