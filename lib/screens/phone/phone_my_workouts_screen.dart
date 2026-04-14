import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/workout.dart';
import '../../providers/auth_provider.dart';
import '../../services/workout_service.dart';
import 'phone_workout_detail_screen.dart';

class PhoneMyWorkoutsScreen extends StatefulWidget {
  const PhoneMyWorkoutsScreen({super.key});

  @override
  State<PhoneMyWorkoutsScreen> createState() => _PhoneMyWorkoutsScreenState();
}

class _PhoneMyWorkoutsScreenState extends State<PhoneMyWorkoutsScreen> {
  late WorkoutService _workoutService;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final coach = authProvider.currentCoach;
    final gym = authProvider.currentGym;

    if (coach == null || gym == null) {
      return Center(
        child: Text(
          'Not authenticated',
          style: GoogleFonts.barlow(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return StreamBuilder<List<Workout>>(
      stream: _workoutService.getWorkoutsStreamForCoach(coach.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.barlow(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        final workouts = snapshot.data ?? [];

        if (workouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Workouts Yet',
                  style: GoogleFonts.barlow(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first workout',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
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
            return _buildWorkoutCard(workout);
          },
        );
      },
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final durationMinutes = workout.getTotalDuration() ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhoneWorkoutDetailScreen(
                  workout: workout,
                  workoutService: _workoutService,
                ),
              ),
            );
          },
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
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  workout.description,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: Colors.black54,
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
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${workout.exercises.length} exercises',
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$durationMinutes min',
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (workout.rounds > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${workout.rounds} rounds',
                            style: GoogleFonts.barlow(
                              fontSize: 11,
                              color: const Color(0xFF3B82F6),
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
}
