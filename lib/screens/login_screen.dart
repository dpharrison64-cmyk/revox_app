import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
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
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to access your gym',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'email@example.com',
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
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Login'),
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
