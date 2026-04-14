import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_tab_screen.dart';

class TabletWelcomeScreen extends StatelessWidget {
  const TabletWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'STUDIO',
                    textScaleFactor: 1.0,
                    textAlign: TextAlign.center,
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
              const SizedBox(height: 100),
              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TabletCoachLoginScreen(),
                    ),
                  );
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
              const SizedBox(height: 16),
              // Admin Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TabletAdminLoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Admin Login',
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Coach login (uses existing AuthTabScreen)
class TabletCoachLoginScreen extends StatelessWidget {
  const TabletCoachLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const AuthTabScreen(),
    );
  }
}

// Admin code login
class TabletAdminLoginScreen extends StatefulWidget {
  const TabletAdminLoginScreen({super.key});

  @override
  State<TabletAdminLoginScreen> createState() => _TabletAdminLoginScreenState();
}

class _TabletAdminLoginScreenState extends State<TabletAdminLoginScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithAdminCode(
      _codeController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop(); // Pop back to welcome
      // The TabletNavigator will now see authenticated + adminType='tablet'
      // and show TabletAdminDashboard
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
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
          onPressed: () => Navigator.pop(context),
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
                  'Admin Login',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _codeController,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Admin Code',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter admin code',
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
                  onPressed: authProvider.isLoading ? null : _handleAdminLogin,
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
