import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HostManageCoachesScreen extends StatelessWidget {
  const HostManageCoachesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Coaches',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            Text(
              'Coach Management',
              style: GoogleFonts.barlow(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: GoogleFonts.barlow(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
