import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../providers/auth_provider.dart';
import '../services/active_workout_service.dart';
import 'workout_control_dialog.dart';

class HostCoachWorkoutListScreen extends StatefulWidget {
  const HostCoachWorkoutListScreen({super.key});

  @override
  State<HostCoachWorkoutListScreen> createState() =>
      _HostCoachWorkoutListScreenState();
}

class _HostCoachWorkoutListScreenState extends State<HostCoachWorkoutListScreen> {
  final _firestore = FirebaseFirestore.instance;
  late String _selectedCoachId;
  UniqueKey _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedCoachId = context.read<AuthProvider>().hostCoachCode ?? '';
  }

  Future<void> _refreshWorkouts() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  Future<List<Workout>> _fetchCoachWorkouts() async {
    if (_selectedCoachId.isEmpty) {
      return [];
    }

    try {
      final gymId = context.read<AuthProvider>().currentGym?.id;
      if (gymId == null) return [];

      final query = await _firestore
          .collection('workouts')
          .where('coachId', isEqualTo: _selectedCoachId)
          .where('gymId', isEqualTo: gymId)
          .get();

      final workouts = query.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Workout.fromJson(data);
          })
          .toList();

      // Sort by updatedAt descending
      workouts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }

  Future<String> _fetchCoachName() async {
    try {
      final coachDoc = await _firestore.collection('coaches').doc(_selectedCoachId).get();
      if (coachDoc.exists) {
        return coachDoc.data()?['name'] ?? 'Coach';
      }
      return 'Coach';
    } catch (e) {
      return 'Coach';
    }
  }

  Future<void> _startWorkout(String workoutId) async {
    try {
      // Fetch the workout
      final workoutDoc = await _firestore.collection('workouts').doc(workoutId).get();
      if (!workoutDoc.exists) {
        throw Exception('Workout not found');
      }

      final data = workoutDoc.data()!;
      data['id'] = workoutDoc.id;
      final workout = Workout.fromJson(data);

      // Get gym and coach info
      final authProvider = context.read<AuthProvider>();
      final gymId = authProvider.currentGym?.id;
      final coachId = _selectedCoachId;

      if (gymId == null || coachId.isEmpty) {
        throw Exception('Gym or Coach not found');
      }

      print('[Workout] Starting workout: ${workout.name}');

      // Start the workout via ActiveWorkoutService
      final activeWorkoutService = ActiveWorkoutService();
      await activeWorkoutService.startWorkout(gymId, coachId, workout);

      print('[Workout] Workout started successfully');

      if (mounted) {
        // Show the workout control dialog
        final stopped = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => WorkoutControlDialog(
            gymId: gymId,
            workoutName: workout.name,
          ),
        );

        // If workout was stopped, show message
        if (stopped == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Workout "${workout.name}" stopped!'),
                backgroundColor: Colors.red,
              ),
            );
            _refreshWorkouts();
          }
        }
      }
    } catch (e) {
      print('[Workout] Error starting workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the gym's primary color
    final gymPrimaryColor = context.read<AuthProvider>().getGymPrimaryColor();
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f0f0f),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[800]!,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: Text(
                        'Sign out?',
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to sign out of your dashboard?',
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.barlow(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            context.read<AuthProvider>().clearHostCoachCode();
                            Navigator.of(context).pop(); // Go back
                          },
                          child: Text(
                            'Yes',
                            style: GoogleFonts.barlow(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(
                right: BorderSide(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SPRTN STUDIO Logo - DO NOT EDIT
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Text(
                        'STUDIO',
                        textScaleFactor: 1.0,
                        style: GoogleFonts.barlow(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Positioned(
                        left: 2,
                        top: -4,
                        child: Text(
                          'SPRTN',
                          textScaleFactor: 1.0,
                          style: GoogleFonts.barlow(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Coach Name and Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FutureBuilder<String>(
                    future: _fetchCoachName(),
                    builder: (context, snapshot) {
                      String coachName = 'Coach';
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        coachName = snapshot.data ?? 'Coach';
                      }
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[700]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  coachName,
                                  style: GoogleFonts.barlow(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coach View',
                                  style: GoogleFonts.barlow(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: gymPrimaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right Side - Workouts List
          Expanded(
            child: Column(
              children: [
                // Title with Refresh Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coach Workouts',
                        style: GoogleFonts.barlow(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: context.read<AuthProvider>().getGymPrimaryColor(),
                        ),
                        onPressed: _refreshWorkouts,
                        tooltip: 'Refresh workouts',
                      ),
                    ],
                  ),
                ),
                // Workouts ListView
                Expanded(
                  child: FutureBuilder<List<Workout>>(
                    key: _refreshKey,
                    future: _fetchCoachWorkouts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: gymPrimaryColor),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final workouts = snapshot.data ?? [];

                      if (workouts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No workouts yet',
                                style: GoogleFonts.barlow(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Coach has not created any workouts',
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          return _buildWorkoutCard(workout, gymPrimaryColor);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, Color primaryColor) {
    final durationMinutes = workout.getTotalDuration() ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1e1e1e),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWorkoutDetails(workout, primaryColor),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workout.name,
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: primaryColor, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  workout.description,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${workout.exercises.where((e) => e.name != 'Rest').length} exercises',
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$durationMinutes min',
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (workout.rounds > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${workout.rounds} rounds',
                            style: GoogleFonts.barlow(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
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
    );
  }

  void _showWorkoutDetails(Workout workout, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0f0f0f),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final durationMinutes = workout.getTotalDuration() ~/ 60;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workout Title
                      Text(
                        workout.name,
                        style: GoogleFonts.barlow(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        workout.description,
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Info Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${workout.exercises.where((e) => e.name != 'Rest').length} exercises',
                              style: GoogleFonts.barlow(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$durationMinutes min',
                              style: GoogleFonts.barlow(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (workout.rounds > 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${workout.rounds} rounds',
                                  style: GoogleFonts.barlow(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Exercises Title
                      Text(
                        'Exercises',
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Scrollable Exercises List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, index) {
                      var exercise = workout.exercises[index];
                      
                      // Check if this is a rest period exercise
                      if (exercise.name == 'Rest') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[900]?.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber[700]!,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '⏸ Rest: ${exercise.duration}s',
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber[300],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      // Regular exercise display
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e1e1e),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${exercise.name}',
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (exercise.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    exercise.description,
                                    style: GoogleFonts.barlow(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  if (exercise.duration > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${exercise.duration}s',
                                        style: GoogleFonts.barlow(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  if (exercise.reps > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${exercise.reps} reps',
                                          style: GoogleFonts.barlow(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Fixed Footer with Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _startWorkout(workout.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start Workout',
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
