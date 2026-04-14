import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/active_workout_service.dart';

class WorkoutControlDialog extends StatefulWidget {
  final String gymId;
  final String workoutName;

  const WorkoutControlDialog({
    required this.gymId,
    required this.workoutName,
    super.key,
  });

  @override
  State<WorkoutControlDialog> createState() => _WorkoutControlDialogState();
}

class _WorkoutControlDialogState extends State<WorkoutControlDialog> {
  late ActiveWorkoutService _workoutService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workoutService = ActiveWorkoutService();
  }

  Future<void> _stopWorkout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Stop Workout?',
            style: GoogleFonts.barlow(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Are you sure you want to stop this workout? This cannot be undone.',
            style: GoogleFonts.barlow(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Stop Workout',
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, do nothing
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      print('[WorkoutControl] 🛑 STOP button pressed');
      print('[WorkoutControl] Calling stopWorkout for gym: ${widget.gymId}');
      
      await _workoutService.stopWorkout(widget.gymId);
      
      print('[WorkoutControl] ✅ Stop command completed');
      
      if (mounted) {
        print('[WorkoutControl] Closing dialog and returning to list');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('[WorkoutControl] ❌ Error stopping workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _stopWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
