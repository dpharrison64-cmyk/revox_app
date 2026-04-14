import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PhoneSettingsScreen extends StatelessWidget {
  const PhoneSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coach = context.read<AuthProvider>().currentCoach;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  coach?.name ?? 'Unknown',
                  style: GoogleFonts.barlow(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coach?.email ?? 'unknown@email.com',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Change Password Button
          ElevatedButton(
            onPressed: () {
              _showChangePasswordDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Change Password',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Delete Account Button
          ElevatedButton(
            onPressed: () {
              _showDeleteAccountDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
              ),
            ),
            child: Text(
              'Delete Account',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Logout Button
          ElevatedButton(
            onPressed: () {
              _showLogoutDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[50],
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Logout',
          style: GoogleFonts.barlow(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.barlow(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/welcome');
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.barlow(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Change Password',
            style: GoogleFonts.barlow(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.barlow(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                // TODO: Implement password change in AuthService
                // context.read<AuthProvider>().changePassword(
                //   currentPasswordController.text,
                //   newPasswordController.text,
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password change feature coming soon')),
                );
                Navigator.pop(context);
              },
              child: Text(
                'Change',
                style: GoogleFonts.barlow(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    _showStep1DeleteDialog(context);
  }

  void _showStep1DeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Account?',
          style: GoogleFonts.barlow(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.barlow(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showStep2DeleteDialog(context);
            },
            child: Text(
              'Yes, Delete',
              style: GoogleFonts.barlow(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStep2DeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'This Cannot Be Undone',
          style: GoogleFonts.barlow(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'All your workouts, data, and this account will be permanently deleted from our servers. You will lose access to everything.',
          style: GoogleFonts.barlow(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showStep3DeleteDialog(context);
            },
            child: Text(
              'I Understand, Delete',
              style: GoogleFonts.barlow(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStep3DeleteDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    bool dialogActive = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => WillPopScope(
          onWillPop: () async => !isDeleting,
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Confirm with Password',
              style: GoogleFonts.barlow(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your password to permanently delete your account:',
                  style: GoogleFonts.barlow(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () {
                        dialogActive = false;
                        Navigator.pop(context);
                        passwordController.dispose();
                      },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.barlow(
                    color: isDeleting ? Colors.black12 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your password')),
                          );
                          return;
                        }

                        setState(() => isDeleting = true);

                        try {
                          final success =
                              await context.read<AuthProvider>().deleteAccount(
                                    passwordController.text,
                                  );

                          if (!dialogActive) return;

                          if (success) {
                            Navigator.pop(context);
                            passwordController.dispose();
                            // Navigate to auth screen after successful deletion
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account deleted successfully'),
                              ),
                            );
                          } else {
                            if (dialogActive) {
                              setState(() => isDeleting = false);
                              final errorMsg =
                                  context.read<AuthProvider>().errorMessage ??
                                      'Failed to delete account';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg)),
                              );
                            }
                          }
                        } catch (e) {
                          if (dialogActive) {
                            setState(() => isDeleting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                child: isDeleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.red.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Text(
                        'Delete My Account',
                        style: GoogleFonts.barlow(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      dialogActive = false;
      passwordController.dispose();
    });
  }
}
