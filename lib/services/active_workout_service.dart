import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

class ActiveWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create/start a new active workout
  Future<void> startWorkout(String gymId, String coachId, Workout workout) async {
    try {
      print('[ActiveWorkout] 🔄 STARTING FRESH WORKOUT: ${workout.name}');
      
      // Step 1: Completely delete any existing workout document to ensure clean state
      try {
        await _firestore.collection('active_workouts').doc(gymId).delete();
        print('[ActiveWorkout] ✅ Deleted any previous workout');
      } catch (e) {
        print('[ActiveWorkout] ℹ️  No previous workout to delete: $e');
      }
      
      // Step 2: Long delay to ensure Firestore completely processes deletion
      await Future.delayed(const Duration(milliseconds: 800));
      print('[ActiveWorkout] ⏳ Deletion buffer complete');
      
      // Step 3: Create a completely fresh workout document
      // CRITICAL: ALWAYS reset to index 0, never resume from previous position
      final freshWorkoutData = {
        'gymId': gymId,
        'coachId': coachId,
        'workoutId': workout.id,
        'workoutName': workout.name,
        'status': 'running',
        'currentExerciseIndex': 0, // ALWAYS ZERO - fresh start
        'currentPhaseStartTime': Timestamp.now(),
        'startedAt': Timestamp.now(),
        'exercises': workout.exercises.map((e) => {
          'id': e.id,
          'name': e.name,
          'duration': e.duration,
          'restAfter': e.restAfter,
        }).toList(),
      };
      
      print('[ActiveWorkout] 📝 Creating fresh workout with index 0...');
      print('[ActiveWorkout] Workout name: ${workout.name}');
      print('[ActiveWorkout] Total exercises: ${workout.exercises.length}');
      print('[ActiveWorkout] First exercise: ${workout.exercises.isNotEmpty ? workout.exercises[0].name : 'N/A'}');
      
      await _firestore.collection('active_workouts').doc(gymId).set(freshWorkoutData);
      print('[ActiveWorkout] ✅ Fresh workout document created');
      
      // Step 4: Wait for Firestore propagation
      await Future.delayed(const Duration(milliseconds: 500));
      print('[ActiveWorkout] ✅ WORKOUT READY - Listeners should have fresh data at exercise 0');
    } catch (e) {
      print('[ActiveWorkout] ❌ ERROR starting workout: $e');
      throw Exception('Failed to start workout: $e');
    }
  }

  // Pause the workout
  Future<void> pauseWorkout(String gymId) async {
    try {
      print('[ActiveWorkout] ⏸️  PAUSING workout...');
      
      // Get current document to capture elapsed time
      final doc = await _firestore.collection('active_workouts').doc(gymId).get();
      if (!doc.exists) {
        throw Exception('Workout not found');
      }
      
      final data = doc.data()!;
      final startedAt = data['startedAt'] as Timestamp?;
      final currentExerciseIndex = data['currentExerciseIndex'] as int? ?? 0;
      
      if (startedAt != null) {
        final now = DateTime.now();
        final elapsedSeconds = now.difference(startedAt.toDate()).inSeconds;
        
        print('[ActiveWorkout] Current elapsed: ${elapsedSeconds}s');
        print('[ActiveWorkout] Current exercise index: ${currentExerciseIndex}');
        print('[ActiveWorkout] Storing paused state...');
        
        // Update to paused and store the elapsed time we had when paused
        await _firestore.collection('active_workouts').doc(gymId).update({
          'status': 'paused',
          'pausedElapsedSeconds': elapsedSeconds, // Store for resume calculation
          'pausedExerciseIndex': currentExerciseIndex, // Store which round we're in
          'pausedAt': Timestamp.now(),
        });
        
        print('[ActiveWorkout] ✅ Workout PAUSED at ${elapsedSeconds}s, exercise index: ${currentExerciseIndex}');
      }
    } catch (e) {
      print('[ActiveWorkout] ❌ Error pausing: $e');
      throw Exception('Failed to pause workout: $e');
    }
  }

  // Resume the workout
  Future<void> resumeWorkout(String gymId) async {
    try {
      print('[ActiveWorkout] ▶️  RESUMING workout...');
      
      // Get current document to calculate new startedAt based on pausedElapsedSeconds
      final doc = await _firestore.collection('active_workouts').doc(gymId).get();
      if (!doc.exists) {
        throw Exception('Workout not found');
      }
      
      final data = doc.data()!;
      final pausedElapsedSeconds = (data['pausedElapsedSeconds'] as int?) ?? 0;
      
      print('[ActiveWorkout] Resuming from paused state: ${pausedElapsedSeconds}s elapsed');
      
      // Calculate new startedAt time so that elapsed will be pausedElapsedSeconds
      // new startedAt = now - pausedElapsedSeconds
      final now = DateTime.now();
      final newStartedAt = now.subtract(Duration(seconds: pausedElapsedSeconds));
      
      print('[ActiveWorkout] New startedAt calculated to maintain elapsed time');
      
      // Update to running and adjust startedAt only (don't reset phase timing)
      await _firestore.collection('active_workouts').doc(gymId).update({
        'status': 'running',
        'startedAt': Timestamp.fromDate(newStartedAt),
        'pausedElapsedSeconds': FieldValue.delete(), // Remove paused marker
        'pausedExerciseIndex': FieldValue.delete(), // Remove paused exercise index
        'pausedAt': FieldValue.delete(),
      });
      
      print('[ActiveWorkout] ✅ Workout RESUMED - timer continues from ${pausedElapsedSeconds}s');
    } catch (e) {
      print('[ActiveWorkout] ❌ Error resuming: $e');
      throw Exception('Failed to resume workout: $e');
    }
  }

  // Skip to next exercise
  Future<void> nextExercise(String gymId) async {
    try {
      final doc = await _firestore.collection('active_workouts').doc(gymId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final currentIndex = (data['currentExerciseIndex'] as int) + 1;
        final exercises = data['exercises'] as List;
        
        if (currentIndex >= exercises.length) {
          // Workout finished
          await _firestore.collection('active_workouts').doc(gymId).update({
            'status': 'finished',
            'finishedAt': Timestamp.now(),
          });
        } else {
          await _firestore.collection('active_workouts').doc(gymId).update({
            'currentExerciseIndex': currentIndex,
            'status': 'running',
            'currentPhaseStartTime': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to advance exercise: $e');
    }
  }

  // Stop/reset the workout - COMPLETELY removes it from Firestore with verification
  Future<void> stopWorkout(String gymId) async {
    try {
      print('[ActiveWorkout] 🛑 HARD KILLING WORKOUT FOR GYM: $gymId');
      
      // Step 1: Delete the active workout document
      print('[ActiveWorkout] Step 1: Deleting active_workouts document...');
      await _firestore.collection('active_workouts').doc(gymId).delete();
      print('[ActiveWorkout] ✅ Delete command sent');
      
      // Step 2: Wait for Firestore to process deletion
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 3: Verify deletion - check that document no longer exists
      print('[ActiveWorkout] Step 3: Verifying deletion...');
      final verifyDoc = await _firestore.collection('active_workouts').doc(gymId).get();
      
      if (verifyDoc.exists) {
        print('[ActiveWorkout] ❌ DELETION FAILED - Document still exists!');
        print('[ActiveWorkout] Attempting force delete again...');
        
        // Try deleting again if first attempt failed
        await _firestore.collection('active_workouts').doc(gymId).delete();
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify second attempt
        final verifyDoc2 = await _firestore.collection('active_workouts').doc(gymId).get();
        if (verifyDoc2.exists) {
          throw Exception('Failed to delete workout - document persists');
        } else {
          print('[ActiveWorkout] ✅ Force delete successful');
        }
      } else {
        print('[ActiveWorkout] ✅ Verified: Workout document completely deleted from Firestore');
      }
      
      // Step 4: Additional wait for stream propagation
      await Future.delayed(const Duration(milliseconds: 300));
      print('[ActiveWorkout] ✅ WORKOUT FULLY HARD KILLED - Streams should update');
    } catch (e) {
      print('[ActiveWorkout] ❌ Error hard killing workout: $e');
      throw Exception('Failed to stop workout: $e');
    }
  }

  // Listen to active workout (for Pi display)
  Stream<Map<String, dynamic>?> getActiveWorkoutStream(String gymId) {
    print('[ActiveWorkout] 🔄 Starting stream listener for gym: $gymId');
    return _firestore.collection('active_workouts').doc(gymId).snapshots().map((doc) {
      if (doc.exists) {
        print('[ActiveWorkout] 📡 Stream event: Document exists with data');
        return doc.data();
      }
      print('[ActiveWorkout] 📡 Stream event: Document does not exist');
      return null;
    });
  }

  // Get active workout once
  Future<Map<String, dynamic>?> getActiveWorkout(String gymId) async {
    try {
      final doc = await _firestore.collection('active_workouts').doc(gymId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active workout: $e');
    }
  }

  // Advance to rest phase
  Future<void> advanceToRest(String gymId) async {
    final docId = '${gymId}_active';
    await _firestore.collection('gyms').doc(gymId).collection('active_workout').doc(docId).update({
      'status': 'rest',
      'currentPhaseStartTime': Timestamp.now(),
    });
  }
}
