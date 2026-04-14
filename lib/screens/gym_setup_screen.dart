import 'package:flutter/material.dart';

// This screen is no longer used - gym setup is now handled via manual database creation
class GymSetupScreen extends StatelessWidget {
  const GymSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GymSetupScreen - No longer in use',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
