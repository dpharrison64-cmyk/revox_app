import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../providers/auth_provider.dart';
import '../../services/workout_service.dart';
import 'package:uuid/uuid.dart';

class PhoneCreateWorkoutScreen extends StatefulWidget {
  const PhoneCreateWorkoutScreen({super.key});

  @override
  State<PhoneCreateWorkoutScreen> createState() =>
      _PhoneCreateWorkoutScreenState();
}

class _PhoneCreateWorkoutScreenState extends State<PhoneCreateWorkoutScreen> {
  late WorkoutService _workoutService;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<Exercise> _exercises;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _exercises = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // Sync auth state with WorkoutService before creating
      if (authProvider.currentCoach != null && authProvider.currentGym != null) {
        _workoutService.syncAuthState(authProvider.currentCoach!, authProvider.currentGym!);
      }
      
      final roundsCount = _exercises.where((e) => e.name != 'Rest').length;
      final workout = Workout(
        id: const Uuid().v4(),
        gymId: authProvider.currentGym?.id ?? '',
        coachId: authProvider.currentCoach?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        exercises: _exercises,
        rounds: roundsCount > 0 ? roundsCount : 1,
      );

      await _workoutService.createWorkout(workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to Workout',
              style: GoogleFonts.barlow(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddRoundDialog();
              },
              icon: const Icon(Icons.fitness_center),
              label: Text(
                'Add Exercise',
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddRestDialog();
              },
              icon: const Icon(Icons.pause_circle),
              label: Text(
                'Add Rest',
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _showAddRestDialog() {
    final restNumber = _exercises.where((e) => e.name != 'Rest').length + 1;
    final durationController = TextEditingController(text: '1:00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Rest $restNumber',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Rest Duration',
                  hintText: 'e.g., 1:00 or 0:30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final duration = _parseTimeString(durationController.text);
                  final newRest = Exercise(
                    id: const Uuid().v4(),
                    name: 'Rest',
                    duration: duration,
                    reps: 0,
                    restAfter: 0,
                  );
                  Navigator.pop(context);
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _exercises.add(newRest);
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Rest',
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRoundDialog() {
    final roundNumber = _exercises.where((e) => e.name != 'Rest').length + 1;
    final durationController = TextEditingController(text: '3:00');
    final focusController = TextEditingController();
    final restAfterController = TextEditingController(text: '1:00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Round $roundNumber',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Round Duration',
                  hintText: 'e.g., 3:00 or 1:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: focusController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Exercises/Focus',
                  hintText: 'e.g., 1-2 combos, footwork drills',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: restAfterController,
                decoration: InputDecoration(
                  labelText: 'Rest Duration After (optional)',
                  hintText: 'e.g., 1:00 or 0:30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final duration = _parseTimeString(durationController.text);
                  final restAfter = _parseTimeString(restAfterController.text);
                  final newExercise = Exercise(
                    id: const Uuid().v4(),
                    name: focusController.text.isNotEmpty
                        ? focusController.text
                        : 'Round',
                    duration: duration,
                    reps: 0,
                    restAfter: restAfter,
                  );
                  Navigator.pop(context);
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _exercises.add(newExercise);
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Round',
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  int _parseTimeString(String timeStr) {
    // Parse MM:SS or just number of minutes
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final minutes = int.tryParse(parts[0]) ?? 3;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    } else {
      final minutes = int.tryParse(timeStr) ?? 3;
      return minutes * 60;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          'Create Workout',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Create',
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Section
            Text(
              'Workout Name',
              style: GoogleFonts.barlow(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: true,
              decoration: InputDecoration(
                hintText: 'Enter workout name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Description Section
            Row(
              children: [
                Text(
                  'Description',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(Optional)',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black38,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter workout description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Exercises Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises (${_exercises.length})',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMenu,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'No exercises yet',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int index = 0; index < _exercises.length; index++)
                    _buildExerciseCard(_exercises[index], index),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    final isRest = exercise.name == 'Rest';

    if (isRest) {
      return Container(
        key: ValueKey(exercise.id),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.orange.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.pause_circle,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(exercise.duration),
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteExercise(index),
              child: Icon(
                Icons.close,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey(exercise.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_handle,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(exercise.duration)}${exercise.reps > 0 ? ' • ${exercise.reps} reps' : ''}${exercise.restAfter > 0 ? ' • Rest: ${_formatDuration(exercise.restAfter)}' : ''}',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteExercise(index),
            child: Icon(
              Icons.close,
              color: Colors.red.shade400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
