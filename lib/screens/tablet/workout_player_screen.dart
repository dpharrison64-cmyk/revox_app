import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutPlayerScreen({super.key, required this.workout});

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  int _currentRound = 1;
  int _currentExerciseIndex = 0;
  int _remainingTime = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _setup();
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
    // Play transition sound or notification
    _showTransitionDialog();

    // Move to next exercise or complete
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _remainingTime = _getCurrentExercise().duration;
      });
    } else if (_currentRound < widget.workout.rounds) {
      setState(() {
        _currentRound++;
        _currentExerciseIndex = 0;
        _remainingTime = _getCurrentExercise().duration;
      });
    } else {
      // Workout complete
      _isRunning = false;
      _countdownController.stop();
      _showWorkoutCompleteDialog();
    }
  }

  void _showTransitionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exercise Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            if (_currentExerciseIndex < widget.workout.exercises.length - 1)
              Column(
                children: [
                  Text(
                    'Next: ${widget.workout.exercises[_currentExerciseIndex + 1].name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting in 3 seconds...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Text(
                _currentRound < widget.workout.rounds
                    ? 'Round ${_currentRound + 1} starting...'
                    : 'Workout complete!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isRunning) {
        Navigator.pop(context);
        _startCountdown();
      }
    });
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Great job! Keep pushing!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Exercise _getCurrentExercise() {
    return widget.workout.exercises[_currentExerciseIndex];
  }

  void _startCountdown() {
    setState(() => _isRunning = true);
    _countdownController.forward(from: 0);
  }

  void _pauseCountdown() {
    _countdownController.stop();
    setState(() => _isPaused = true);
  }

  void _resumeCountdown() {
    _countdownController.forward();
    setState(() => _isPaused = false);
  }

  void _stopWorkout() {
    _countdownController.stop();
    setState(() => _isRunning = false);
    Navigator.pop(context);
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
        ((_currentExerciseIndex + 1) / widget.workout.exercises.length * 100).toInt();
    final roundProgress = ((_currentRound / widget.workout.rounds) * 100).toInt();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_isRunning) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stop Workout?'),
              content: const Text('Are you sure you want to stop?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _stopWorkout();
                    Navigator.pop(context);
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workout.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _stopWorkout,
          ),
        ),
        body: Row(
          children: [
            // Main display (center)
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withAlpha(200),
                      Theme.of(context).colorScheme.secondary.withAlpha(200),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Exercise name
                    Text(
                      currentExercise.name,
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Timer
                    Text(
                      _formatTime(_remainingTime),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Reps info
                    if (currentExercise.reps > 0)
                      Text(
                        'Reps: ${currentExercise.reps}',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 48),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: !_isRunning ? _startCountdown : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_isRunning)
                          ElevatedButton.icon(
                            onPressed:
                                _isPaused ? _resumeCountdown : _pauseCountdown,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                            ),
                            label: Text(_isPaused ? 'Resume' : 'Pause'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right sidebar - workout info
            Container(
              width: 300,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  // Progress info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildProgressSection(
                          context,
                          'Round',
                          '$_currentRound / ${widget.workout.rounds}',
                          roundProgress,
                        ),
                        const SizedBox(height: 16),
                        _buildProgressSection(
                          context,
                          'Exercise',
                          '${_currentExerciseIndex + 1} / ${widget.workout.exercises.length}',
                          exerciseProgress,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Exercise list
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.workout.exercises.length,
                      itemBuilder: (context, index) {
                        final isActive = index == _currentExerciseIndex;
                        final exercise = widget.workout.exercises[index];
                        return ListTile(
                          selected: isActive,
                          title: Text(exercise.name),
                          subtitle: Text(
                            '${exercise.duration}s${exercise.reps > 0 ? ' • ${exercise.reps} reps' : ''}',
                          ),
                          tileColor: isActive
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(100)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    String label,
    String value,
    int percent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
