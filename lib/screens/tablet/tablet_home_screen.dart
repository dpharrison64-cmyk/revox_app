import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout.dart';
import '../../providers/auth_provider.dart';
import '../../services/workout_service.dart';

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen> {
  late WorkoutService _workoutService;
  Workout? _selectedWorkout;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService();
    // Load pending coaches if this is an admin
    final coach = context.read<AuthProvider>().currentCoach;
    if (coach?.role == 'admin') {
      context.read<AuthProvider>().loadPendingCoaches();
    }
  }

  Future<void> _startWorkout(Workout workout) async {
    setState(() => _isStarting = true);

    try {
      final coach = context.read<AuthProvider>().currentCoach;
      if (coach != null) {
        // Update coach's currentSelectedWorkout in Firestore
        await FirebaseFirestore.instance
            .collection('coaches')
            .doc(coach.id)
            .update({
          'currentSelectedWorkout': workout.id,
        });

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Started: ${workout.name}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = context.read<AuthProvider>().currentCoach;
    final isAdmin = coach?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SPRTN STUDIO - Controller'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    coach?.name ?? 'Coach',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    isAdmin ? 'Admin Account' : 'Coach Account',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Pending coaches section (Admin only)
          if (isAdmin)
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.pendingCoaches.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  color: Colors.orange[50],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Coach Requests (${authProvider.pendingCoaches.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: authProvider.pendingCoaches.length,
                          itemBuilder: (context, index) {
                            final pendingCoach = authProvider.pendingCoaches[index];
                            return Card(
                              margin: const EdgeInsets.only(right: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendingCoach.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      pendingCoach.email,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () {
                                            authProvider.approveCoach(pendingCoach.id);
                                          },
                                          child: const Text(
                                            'Approve',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () {
                                            authProvider.rejectCoach(pendingCoach.id);
                                          },
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
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
                      const Divider(),
                    ],
                  ),
                );
              },
            ),
          // Workouts section
          Expanded(
            child: _buildWorkoutsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        // Workout list
        Expanded(
          flex: isMobile ? 1 : 1,
          child: StreamBuilder<List<Workout>>(
            stream: _workoutService.getWorkoutsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final workouts = snapshot.data ?? [];

              if (workouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 96, color: Colors.grey[400]),
                      const SizedBox(height: 32),
                      Text(
                        'No Workouts',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create workouts on the coach app',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  final isSelected = _selectedWorkout?.id == workout.id;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primary.withAlpha(100),
                      title: Text(
                        workout.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${workout.exercises.length} exercises • ${workout.rounds} rounds',
                      ),
                      onTap: () {
                        setState(() => _selectedWorkout = workout);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Detail view
        if (!isMobile && _selectedWorkout != null)
          Expanded(
            flex: 1,
            child: _buildDetailPanel(_selectedWorkout!),
          )
        else if (isMobile && _selectedWorkout != null)
          Expanded(
            flex: 1,
            child: _buildDetailPanel(_selectedWorkout!),
          ),
      ],
    );
  }

  Widget _buildDetailPanel(Workout workout) {
    final durationMinutes = workout.getTotalDuration() ~/ 60;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (workout.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    workout.description,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Exercise list header
                  Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  // Exercise list
                  ...workout.exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${exercise.duration}s${exercise.reps > 0 ? ' • ${exercise.reps} reps' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Summary stats
                  Wrap(
                    spacing: 16,
                    children: [
                      Chip(
                        label: Text('${workout.rounds} rounds'),
                      ),
                      Chip(
                        label: Text('${durationMinutes}m total'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Start button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : () => _startWorkout(workout),
                icon: _isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isStarting ? 'Starting...' : 'Start Workout',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
