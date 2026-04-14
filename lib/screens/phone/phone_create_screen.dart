import 'package:flutter/material.dart';
import 'phone_create_workout_screen.dart';

class PhoneCreateScreen extends StatelessWidget {
  const PhoneCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PhoneCreateWorkoutScreen(),
            ),
          );
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }
}
