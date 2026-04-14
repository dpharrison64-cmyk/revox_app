import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class AuthTabScreen extends StatefulWidget {
  const AuthTabScreen({super.key});

  @override
  State<AuthTabScreen> createState() => _AuthTabScreenState();
}

class _AuthTabScreenState extends State<AuthTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupGymCodeController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  bool _signupGymCodeValidated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupGymCodeController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithEmail(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  Future<void> _handleValidateGymCode() async {
    final authProvider = context.read<AuthProvider>();
    final code = _signupGymCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a gym code')),
      );
      return;
    }

    final isValid = await authProvider.validateGymCode(code);

    if (isValid && mounted) {
      authProvider.setGymCode(code);
      setState(() {
        _signupGymCodeValidated = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid gym code')),
      );
    }
  }

  Future<void> _handleSignup() async {
    // Validate passwords match
    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signupCoach(
      email: _signupEmailController.text.trim(),
      password: _signupPasswordController.text,
      name: _signupNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF3B82F6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Login'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Login Tab
            _buildLoginTab(),
            // Sign Up Tab
            _buildSignUpTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _loginEmailController,
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
                controller: _loginPasswordController,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Login',
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/host-login');
                  },
                  child: Text(
                    'Host Login',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      color: Colors.white54,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignUpTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (!_signupGymCodeValidated) ...[
                // Gym Code Entry
                TextField(
                  controller: _signupGymCodeController,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      authProvider.isLoading ? null : _handleValidateGymCode,
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
                          'Continue',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
              if (_signupGymCodeValidated) ...[
                // Name Field
                TextField(
                  controller: _signupNameController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Your Name',
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
                // Email Field
                TextField(
                  controller: _signupEmailController,
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
                // Password Field
                TextField(
                  controller: _signupPasswordController,
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
                const SizedBox(height: 16),
                // Confirm Password Field
                TextField(
                  controller: _signupConfirmPasswordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
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
                // Sign Up Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleSignup,
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
                          'Sign Up',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Back Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _signupGymCodeValidated = false;
                      _signupGymCodeController.clear();
                    });
                  },
                  child: Text(
                    'Back',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
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
            ],
          ),
        );
      },
    );
  }
}
