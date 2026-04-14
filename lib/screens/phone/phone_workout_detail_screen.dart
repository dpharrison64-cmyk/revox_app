import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../services/workout_service.dart';
import 'package:uuid/uuid.dart';

class PhoneWorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final WorkoutService workoutService;

  const PhoneWorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.workoutService,
  });

  @override
  State<PhoneWorkoutDetailScreen> createState() =>
      _PhoneWorkoutDetailScreenState();
}

class _PhoneWorkoutDetailScreenState extends State<PhoneWorkoutDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<Exercise> _exercises;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _descriptionController =
        TextEditingController(text: widget.workout.description);
    _exercises = List.from(widget.workout.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final updatedWorkout = widget.workout.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        exercises: _exercises,
      );

      await widget.workoutService.updateWorkout(updatedWorkout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout updated successfully!')),
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

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Workout?',
          style: GoogleFonts.barlow(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this workout? This action cannot be undone.',
          style: GoogleFonts.barlow(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWorkout();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.barlow(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkout() async {
    try {
      await widget.workoutService.deleteWorkout(widget.workout.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully!')),
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
    final hasChanges = _nameController.text != widget.workout.name ||
        _descriptionController.text != widget.workout.description ||
        _exercises.length != widget.workout.exercises.length ||
        !_exercisesEqual();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          _isEditing ? 'Edit Workout' : 'Workout Details',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_isEditing && hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
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
                          'Save',
                          style: GoogleFonts.barlow(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            )
          else if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    child: Text(
                      'Edit',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _showDeleteConfirmDialog,
                    child: Text(
                      'Delete',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isEditing
          ? _buildEditView()
          : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Name
          Text(
            widget.workout.name,
            style: GoogleFonts.barlow(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          // Description (only if not empty)
          if (widget.workout.description.isNotEmpty) ...[
            Text(
              widget.workout.description,
              style: GoogleFonts.barlow(
                fontSize: 14,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Exercises
          Text(
            'Exercises',
            style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
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
                  'No exercises',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final isRest = exercise.name == 'Rest';
                
                if (isRest) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.orange.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pause_circle, color: Colors.orange.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Rest - ${_formatDuration(exercise.duration)}',
                              style: GoogleFonts.barlow(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${exercise.name}',
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
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
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
          Text(
            'Description',
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
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
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final exercise = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, exercise);
                });
              },
              children: [
                for (int index = 0; index < _exercises.length; index++)
                  ReorderableDragStartListener(
                    key: ValueKey(_exercises[index].id),
                    index: index,
                    child: _buildExerciseCard(_exercises[index], index),
                  ),
              ],
            ),
        ],
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

  bool _exercisesEqual() {
    if (_exercises.length != widget.workout.exercises.length) {
      return false;
    }
    for (int i = 0; i < _exercises.length; i++) {
      if (_exercises[i].id != widget.workout.exercises[i].id) {
        return false;
      }
    }
    return true;
  }
}
