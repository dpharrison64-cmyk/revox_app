import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../models/coach.dart';
import '../models/gym.dart';
import 'auth_service.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  WorkoutService._internal();

  factory WorkoutService() {
    return _instance;
  }

  // Sync auth state with provider (call before operations if needed)
  void syncAuthState(Coach coach, Gym gym) {
    _authService.setCurrentCoachAndGym(coach, gym);
  }

  // Create and save a new workout
  Future<Workout?> createWorkout(Workout workout) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final currentCoach = _authService.currentCoach;
      final currentGym = _authService.currentGym;

      if (currentCoach == null || currentGym == null) {
        throw Exception('Coach or gym not found');
      }

      // Ensure the workout belongs to the current gym and coach
      final workoutWithMetadata = workout.copyWith(
        gymId: currentGym.id,
        coachId: currentCoach.id,
      );

      await _firestore
          .collection('workouts')
          .doc(workout.id)
          .set(workoutWithMetadata.toJson());

      return workoutWithMetadata;
    } catch (e) {
      throw Exception('Failed to create workout: $e');
    }
  }

  // Get all workouts for current coach
  Future<List<Workout>> getAllWorkouts() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final currentCoach = _authService.currentCoach;
      if (currentCoach == null) {
        throw Exception('Coach not found');
      }

      // Coaches see only their own workouts
      final result = await _firestore
          .collection('workouts')
          .where('coachId', isEqualTo: currentCoach.id)
          .get();

      final workouts = result.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
      // Sort by updatedAt in memory
      workouts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }

  // Get all workouts in current gym (for tablet/admin)
  Future<List<Workout>> getAllWorkoutsInGym() async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final currentGym = _authService.currentGym;
      if (currentGym == null) {
        throw Exception('Gym not found');
      }

      final result = await _firestore
          .collection('workouts')
          .where('gymId', isEqualTo: currentGym.id)
          .get();

      final workouts = result.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
      // Sort by updatedAt in memory
      workouts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
      return workouts;
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }

  // Get a specific workout by ID
  Future<Workout?> getWorkout(String workoutId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final doc = await _firestore
          .collection('workouts')
          .doc(workoutId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final workout = Workout.fromJson(doc.data() as Map<String, dynamic>);

      // Verify coach has access to this workout (same gym)
      final currentGym = _authService.currentGym;
      if (workout.gymId != currentGym?.id) {
        throw Exception('Access denied');
      }

      return workout;
    } catch (e) {
      throw Exception('Failed to fetch workout: $e');
    }
  }

  // Update an existing workout
  Future<void> updateWorkout(Workout workout) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      final updatedWorkout = workout.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('workouts')
          .doc(workout.id)
          .update(updatedWorkout.toJson());
    } catch (e) {
      throw Exception('Failed to update workout: $e');
    }
  }

  // Delete a workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      await _firestore
          .collection('workouts')
          .doc(workoutId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete workout: $e');
    }
  }

  // Stream of workouts for current coach (phone app)
  Stream<List<Workout>> getWorkoutsStream() {
    final currentCoach = _authService.currentCoach;
    
    if (currentCoach == null) {
      // Return empty stream instead of error while auth is initializing
      return Stream.value([]);
    }

    return _firestore
        .collection('workouts')
        .where('coachId', isEqualTo: currentCoach.id)
        .snapshots()
        .map((snapshot) {
      final workouts = snapshot.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
      // Sort by updatedAt in memory instead of requiring a database index
      workouts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
      return workouts;
    });
  }

  // Stream of workouts for a specific coach (with coach ID passed explicitly)
  Stream<List<Workout>> getWorkoutsStreamForCoach(String coachId) {
    return _firestore
        .collection('workouts')
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snapshot) {
      final workouts = snapshot.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
      // Sort by updatedAt in memory instead of requiring a database index
      workouts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
      return workouts;
    });
  }

  // Stream of all workouts in gym (tablet app)
  Stream<List<Workout>> getGymWorkoutsStream() {
    if (!_authService.isAuthenticated) {
      return Stream.error(Exception('Not authenticated'));
    }

    final currentGym = _authService.currentGym;
    if (currentGym == null) {
      return Stream.error(Exception('Gym not found'));
    }

    return _firestore
        .collection('workouts')
        .where('gymId', isEqualTo: currentGym.id)
        .snapshots()
        .map((snapshot) {
      final workouts = snapshot.docs
          .map((doc) => Workout.fromJson(doc.data()))
          .toList();
      // Sort by updatedAt in memory instead of requiring a database index
      workouts.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
      return workouts;
    });
  }
}
