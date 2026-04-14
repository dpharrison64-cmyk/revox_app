import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gymPrimaryColor = context.read<AuthProvider>().getGymPrimaryColor();
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f0f0f),
        elevation: 0,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: gymPrimaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.settings, color: gymPrimaryColor),
              onPressed: () {
                _showPasswordDialog(context);
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 100),
            // Coach Login Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/host-coach-code');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: gymPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Coach Login',
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    final gymPrimaryColor = context.read<AuthProvider>().getGymPrimaryColor();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f0f0f),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gymPrimaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Settings',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your password to continue',
                    style: GoogleFonts.barlow(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: GoogleFonts.barlow(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gymPrimaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: passwordController,
                          style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          obscureText: !isPasswordVisible,
                          cursorColor: gymPrimaryColor,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintText: 'Enter password',
                            hintStyle: GoogleFonts.barlow(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: gymPrimaryColor.withOpacity(0.6),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.barlow(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (passwordController.text.isNotEmpty) {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamed('/host-settings');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gymPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Access',
                            style: GoogleFonts.barlow(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
