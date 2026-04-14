import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Get Started',
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
