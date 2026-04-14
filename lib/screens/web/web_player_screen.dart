import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';

class WebPlayerScreen extends StatefulWidget {
  final Workout workout;
  final VoidCallback onComplete;

  const WebPlayerScreen({
    super.key,
    required this.workout,
    required this.onComplete,
  });

  @override
  State<WebPlayerScreen> createState() => _WebPlayerScreenState();
}

class _WebPlayerScreenState extends State<WebPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  int _currentRound = 1;
  int _currentExerciseIndex = 0;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _setup();
    // Auto-start immediately
    Future.delayed(const Duration(milliseconds: 500), _startCountdown);
  }

  void _setup() {
    final exercise = _getCurrentExercise();
    _remainingTime = exercise.duration;
    _countdownController.addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _remainingTime--;
        if (_remainingTime <= 0) {
          _onTimeExpired();
        }
      });
      _countdownController.forward(from: 0);
    }
  }

  void _onTimeExpired() {
    // Auto-advance to next exercise
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _remainingTime = _getCurrentExercise().duration;
      });
      // Brief pause for visual feedback
      _countdownController.stop();
      Future.delayed(const Duration(seconds: 2), _startCountdown);
    } else if (_currentRound < widget.workout.rounds) {
      setState(() {
        _currentRound++;
        _currentExerciseIndex = 0;
        _remainingTime = _getCurrentExercise().duration;
      });
      // Brief pause for visual feedback
      _countdownController.stop();
      Future.delayed(const Duration(seconds: 2), _startCountdown);
    } else {
      // Workout complete
      _countdownController.stop();
      _showWorkoutCompleteScreen();
    }
  }

  void _showWorkoutCompleteScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          color: Colors.green[700],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 150,
              ),
              const SizedBox(height: 48),
              const Text(
                'Workout Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Great job! Keep pushing!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-return to home after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  Exercise _getCurrentExercise() {
    return widget.workout.exercises[_currentExerciseIndex];
  }

  void _startCountdown() {
    _countdownController.forward(from: 0);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = _getCurrentExercise();
    final exerciseProgress =
        ((_currentExerciseIndex + 1) / widget.workout.exercises.length * 100)
            .toInt();
    final roundProgress =
        ((_currentRound / widget.workout.rounds) * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Main display (2/3 width)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Exercise name - very large for TV
                  Text(
                    currentExercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),
                  // Timer - huge for visibility
                  Text(
                    _formatTime(_remainingTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 200,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Reps info if applicable
                  if (currentExercise.reps > 0)
                    Text(
                      'Reps: ${currentExercise.reps}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 48,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Right sidebar (1/3 width) - Progress info
          Container(
            width: MediaQuery.of(context).size.width / 3,
            color: Colors.grey[900],
            child: Column(
              children: [
                // Workout title
                Container(
                  color: Colors.blue[900],
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress sections
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Round progress
                        Text(
                          'Round',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_currentRound / ${widget.workout.rounds}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: roundProgress / 100,
                            minHeight: 16,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Exercise progress
                        Text(
                          'Exercise',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_currentExerciseIndex + 1} / ${widget.workout.exercises.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: exerciseProgress / 100,
                            minHeight: 16,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Exercise list
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exercises',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...widget.workout.exercises
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final exercise = entry.value;
                                  final isActive =
                                      index == _currentExerciseIndex;

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.blue[700]
                                          : Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${exercise.duration}s${exercise.reps > 0 ? ' • ${exercise.reps} reps' : ''}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
