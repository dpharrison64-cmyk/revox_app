import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/workout.dart';
import '../../providers/auth_provider.dart';
import '../../services/workout_service.dart';
import 'web_player_screen.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  late WorkoutService _workoutService;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService();
    _setUpWorkoutWatcher();
  }

  void _setUpWorkoutWatcher() {
    // Watch for changes to currentSelectedWorkout in AuthProvider
    final authProvider = context.read<AuthProvider>();
    authProvider.addListener(_checkForSelectedWorkout);
  }

  void _checkForSelectedWorkout() async {
    final authProvider = context.read<AuthProvider>();
    final coach = authProvider.currentCoach;

    if (coach?.currentSelectedWorkout != null && coach!.currentSelectedWorkout!.isNotEmpty) {
      // Load the selected workout
      final workout = await _workoutService.getWorkout(coach.currentSelectedWorkout!);
      if (workout != null) {
        // Show the player
        if (mounted) {
          _showWorkoutPlayer(workout);
        }
      }
    }
  }

  void _showWorkoutPlayer(Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => WebPlayerScreen(
          workout: workout,
          onComplete: _onWorkoutComplete,
        ),
      ),
    );
  }

  void _onWorkoutComplete() {
    // Clear the selected workout to return to idle state
    final authProvider = context.read<AuthProvider>();
    final coach = authProvider.currentCoach;
    if (coach != null) {
      // Update coach to clear currentSelectedWorkout
      FirebaseFirestore.instance
          .collection('coaches')
          .doc(coach.id)
          .update({'currentSelectedWorkout': null});
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_checkForSelectedWorkout);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SPRTN STUDIO Logo / Branding
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPRTN',
                  style: GoogleFonts.barlow(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    height: 0.9,
                  ),
                ),
                Text(
                  'STUDIO',
                  style: GoogleFonts.barlow(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    height: 0.9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final coach = authProvider.currentCoach;
                return Text(
                  'Coach: ${coach?.name ?? "Loading..."}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    );
  }
}
