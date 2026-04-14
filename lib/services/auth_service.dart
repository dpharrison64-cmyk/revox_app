import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/coach.dart';
import '../models/gym.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Coach? _currentCoach;
  Gym? _currentGym;

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  Coach? get currentCoach => _currentCoach;
  Gym? get currentGym => _currentGym;
  bool get isAuthenticated => _auth.currentUser != null;

  // Setter to sync with AuthProvider
  void setCurrentCoachAndGym(Coach coach, Gym gym) {
    _currentCoach = coach;
    _currentGym = gym;
  }

  // Generate a unique 4-digit coach code
  Future<String> _generateUniqueCoachCode() async {
    const maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final randomCode = (1000 + Random().nextInt(9000)).toString();
      
      // Check if code already exists
      final existing = await _firestore
          .collection('coaches')
          .where('coachCode', isEqualTo: randomCode)
          .limit(1)
          .get();
      
      if (existing.docs.isEmpty) {
        return randomCode;
      }
    }
    
    throw Exception('Failed to generate unique coach code');
  }

  // Authenticate with email and password using Firebase Auth
  Future<Map<String, dynamic>?> authenticateWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Sign in with Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get coach data from Firestore
      final result = await _firestore
          .collection('coaches')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        throw Exception('Coach profile not found');
      }

      final coachData = result.docs.first.data();
      final coach = Coach.fromJson(coachData, result.docs.first.id);

      // Get the gym
      final gymDoc = await _firestore.collection('gyms').doc(coach.gymId).get();
      if (!gymDoc.exists) {
        throw Exception('Gym not found');
      }

      final gym = Gym.fromJson(gymDoc.data()!, coach.gymId);

      _currentCoach = coach;
      _currentGym = gym;

      return {
        'coach': coach,
        'gym': gym,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Create new coach account with email, password, name, and gymId
  Future<Map<String, dynamic>?> createCoachAccount({
    required String email,
    required String password,
    required String name,
    required String gymId,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Generate unique coach code
      final coachCode = await _generateUniqueCoachCode();

      // Create coach document in Firestore
      final coachData = {
        'email': email,
        'name': name,
        'gymId': gymId,
        'role': 'coach',
        'coachCode': coachCode,
        'isApproved': true,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'currentSelectedWorkout': null,
      };

      await _firestore.collection('coaches').doc(firebaseUser.uid).set(coachData);

      // Get the gym
      final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
      if (!gymDoc.exists) {
        throw Exception('Gym not found');
      }

      final gym = Gym.fromJson(gymDoc.data()!, gymId);
      final coach = Coach(
        id: firebaseUser.uid,
        name: name,
        email: email,
        gymId: gymId,
        coachCode: coachCode,
        role: 'coach',
        isApproved: true,
        status: 'approved',
        createdAt: DateTime.now(),
      );

      _currentCoach = coach;
      _currentGym = gym;

      return {
        'coach': coach,
        'gym': gym,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Account creation failed');
    } catch (e) {
      throw Exception('Account creation failed: $e');
    }
  }

  // Get all pending coaches for a gym
  Future<List<Coach>> getPendingCoachesForGym(String gymId) async {
    try {
      final result = await _firestore
          .collection('coaches')
          .where('gymId', isEqualTo: gymId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return result.docs.map((doc) => Coach.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending coaches: $e');
    }
  }

  // Approve a coach (admin only)
  Future<void> approveCoach(String coachId) async {
    try {
      await _firestore.collection('coaches').doc(coachId).update({
        'status': 'approved',
        'isApproved': true,
      });
    } catch (e) {
      throw Exception('Failed to approve coach: $e');
    }
  }

  // Reject a coach (admin only)
  Future<void> rejectCoach(String coachId) async {
    try {
      await _firestore.collection('coaches').doc(coachId).update({
        'status': 'rejected',
        'isApproved': false,
      });
    } catch (e) {
      throw Exception('Failed to reject coach: $e');
    }
  }

  // Logout
  void logout() {
    _currentCoach = null;
    _currentGym = null;
  }

  // Update coach profile
  Future<void> updateCoach(Coach coach) async {
    try {
      await _firestore.collection('coaches').doc(coach.id).update(coach.toJson());
      _currentCoach = coach;
    } catch (e) {
      throw Exception('Failed to update coach: $e');
    }
  }

  // Update selected workout for tablet display
  Future<void> setSelectedWorkout(String coachId, String? workoutId) async {
    try {
      await _firestore.collection('coaches').doc(coachId).update({
        'currentSelectedWorkout': workoutId,
      });

      if (_currentCoach?.id == coachId) {
        _currentCoach = _currentCoach!.copyWith(currentSelectedWorkout: workoutId);
      }
    } catch (e) {
      throw Exception('Failed to update selected workout: $e');
    }
  }

  // Delete coach account
  Future<void> deleteAccount(String coachId, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user authenticated');
      }

      // Re-authenticate user with password
      final credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credentials);

      // Delete all workouts for this coach
      final workouts = await _firestore
          .collection('workouts')
          .where('coachId', isEqualTo: coachId)
          .get();

      for (var doc in workouts.docs) {
        await doc.reference.delete();
      }

      // Delete coach document from Firestore
      await _firestore.collection('coaches').doc(coachId).delete();

      // Delete user from Firebase Auth
      await user.delete();

      // Clear local state
      _currentCoach = null;
      _currentGym = null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      }
      throw Exception(e.message ?? 'Failed to delete account');
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Re-authenticate user for admin password verification
  Future<void> reauthenticateForAdmin(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      }
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }
}
