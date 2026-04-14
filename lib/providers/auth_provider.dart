import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coach.dart';
import '../models/gym.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  Coach? _currentCoach;
  Coach? _sessionCoach; // Coach selected after admin login for tablet
  Gym? _currentGym;
  String? _currentGymCode;
  bool _isHostMode = false;
  String? _hostCoachCode;
  bool _isLoading = false;
  String? _errorMessage;
  List<Coach> _pendingCoaches = [];
  String? _adminType; // 'tablet' or 'pi'

  AuthProvider() {
    _performInitialization();
  }

  // Perform initialization
  void _performInitialization() {
    // Load auth state without delay - this is synchronous-ish
    _initializeAuth();
  }

  // Initialize auth state from SharedPreferences (uses localStorage on web)
  Future<void> _initializeAuth() async {
    try {
      print('[Auth] Initializing auth state...');
      final prefs = await SharedPreferences.getInstance();
      final coachId = prefs.getString('coach_id');
      final adminType = prefs.getString('admin_type');
      
      print('[Auth] Retrieved from storage - coachId: $coachId, adminType: $adminType');
      
      if (coachId != null && coachId.isNotEmpty) {
        print('[Auth] Found stored coach_id: $coachId - loading from Firestore');
        // Restore coach and gym data
        await _loadCoachAndGym(coachId);
        // Restore admin type if it was set
        if (adminType != null) {
          _adminType = adminType;
          setHostMode(true);
          print('[Auth] Restored admin type: $_adminType - host mode enabled');
        }
      } else {
        print('[Auth] No stored login found - starting fresh');
      }
      // Always notify listeners to update UI after initialization attempt
      notifyListeners();
    } catch (e) {
      print('[Auth] Error during initialization: $e');
      notifyListeners();
    }
  }

  // Load coach and gym data from Firestore
  Future<void> _loadCoachAndGym(String coachId) async {
    try {
      final coachDoc = await _firestore.collection('coaches').doc(coachId).get();
      
      if (coachDoc.exists) {
        _currentCoach = Coach.fromJson(coachDoc.data()!, coachDoc.id);
        
        if (_currentCoach?.gymId != null) {
          final gymDoc = await _firestore.collection('gyms').doc(_currentCoach!.gymId).get();
          if (gymDoc.exists) {
            _currentGym = Gym.fromJson(gymDoc.data()!, gymDoc.id);
          }
        }
      }
    } catch (e) {
      // Only set error message for actual Firestore errors, not SharedPreferences
      if (!e.toString().contains('channel')) {
        _errorMessage = e.toString();
      }
      // Clear corrupted data
      await _clearStoredAuth();
    }
  }

  // Save coach ID and admin type to SharedPreferences (stores to localStorage on web)
  Future<void> _saveAuth(String coachId, {String? adminType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('coach_id', coachId);
      print('[Auth] Saved coach_id: $coachId');
      if (adminType != null) {
        await prefs.setString('admin_type', adminType);
        print('[Auth] Saved admin_type: $adminType');
      }
    } catch (e) {
      print('[Auth] Error saving auth: $e');
    }
  }

  // Clear auth from SharedPreferences (clears from localStorage on web)
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('coach_id');
      await prefs.remove('admin_type');
      print('[Auth] Cleared stored auth');
    } catch (e) {
      print('[Auth] Error clearing auth: $e');
    }
  }

  Coach? get currentCoach => _currentCoach;
  Gym? get currentGym => _currentGym;
  String? get currentGymCode => _currentGymCode;
  bool get isHostMode => _isHostMode;
  String? get hostCoachCode => _hostCoachCode;
  bool get isAuthenticated {
    // For admin users (tcode/pcode), only need _currentCoach to be set
    if (_currentCoach != null && (_adminType == 'tablet' || _adminType == 'pi')) {
      return true;
    }
    // For regular coaches, need both coach and gym
    return _currentCoach != null && _currentGym != null;
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Coach> get pendingCoaches => _pendingCoaches;
  bool get isAdmin => _currentCoach?.role == 'admin';
  String? get adminType => _adminType; // 'tablet' or 'pi'
  Coach? get sessionCoach => _sessionCoach; // Coach selected after admin login

  /// Get the primary color for the current gym
  /// Returns the gym's primary color if available, otherwise defaults to #3B82F6 (blue)
  Color getGymPrimaryColor() {
    if (_currentGym?.primaryColor != null && _currentGym!.primaryColor!.isNotEmpty) {
      try {
        // Parse hex color string (e.g., '#8b0000') to Color
        final hexColor = _currentGym!.primaryColor!.replaceFirst('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        // Fall back to default if parsing fails
        return const Color(0xFF3B82F6);
      }
    }
    // Default to blue if no primary color is set
    return const Color(0xFF3B82F6);
  }
  bool get hasSessionCoach => _sessionCoach != null;

  // Validate gym code by querying Firestore
  Future<bool> validateGymCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = await _firestore
          .collection('gyms')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      _isLoading = false;
      if (query.docs.isNotEmpty) {
        notifyListeners();
        return true;
      }
      _errorMessage = 'Gym code not found';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Store gym code for later use during authentication
  void setGymCode(String code) {
    _currentGymCode = code.toUpperCase();
    notifyListeners();
  }

  // Clear gym code
  void clearGymCode() {
    _currentGymCode = null;
    notifyListeners();
  }

  // Set host mode
  void setHostMode(bool value) {
    _isHostMode = value;
    notifyListeners();
  }

  // Set coach code for host viewing
  void setHostCoachCode(String code) {
    _hostCoachCode = code;
    notifyListeners();
  }

  // Clear coach code (logout from coach view)
  void clearHostCoachCode() {
    _hostCoachCode = null;
    notifyListeners();
  }

  // Login with admin code (tablet or pi)
  Future<bool> loginWithAdminCode(String adminCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trimmedCode = adminCode.trim();
      
      // First try to find by tcode (tablet)
      var query = await _firestore
          .collection('coaches')
          .where('tcode', isEqualTo: trimmedCode)
          .limit(1)
          .get();

      String detectedAdminType = 'tablet';

      // If not found, try pcode (pi)
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection('coaches')
            .where('pcode', isEqualTo: trimmedCode)
            .limit(1)
            .get();
        detectedAdminType = 'pi';
      }

      if (query.docs.isEmpty) {
        _errorMessage = 'Invalid admin code - not found in database';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final adminData = query.docs.first.data();
      final gymId = adminData['gymId'] as String?;

      if (gymId == null) {
        _errorMessage = 'Gym not found for this code';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Load gym data
      final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
      if (!gymDoc.exists) {
        _errorMessage = 'Gym configuration error';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentGym = Gym.fromJson(gymDoc.data()!, gymDoc.id);
      
      // Create a minimal Coach object for admin (don't use fromJson since admin docs may not have all fields)
      try {
        _currentCoach = Coach(
          id: query.docs.first.id,
          name: adminData['name'] ?? 'Admin',
          email: adminData['email'] ?? '',
          gymId: gymId,
          role: 'admin',
          coachCode: 'ADMIN', // Dummy code for admins
        );
      } catch (e) {
        _errorMessage = 'Failed to load admin: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _adminType = detectedAdminType;
      
      await _saveAuth(_currentCoach!.id, adminType: detectedAdminType);
      setHostMode(true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with coach code (tablet display for coach)
  Future<bool> loginWithCoachCode(String coachCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trimmedCode = coachCode.trim();

      if (trimmedCode.isEmpty) {
        _errorMessage = 'Please enter a coach code';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Find coach by coachCode
      var query = await _firestore
          .collection('coaches')
          .where('coachCode', isEqualTo: trimmedCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _errorMessage = 'Invalid coach code';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final coachData = query.docs.first.data();
      final gymId = coachData['gymId'] as String?;

      if (gymId == null) {
        _errorMessage = 'Coach gym not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verify the gym exists
      final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
      if (!gymDoc.exists) {
        _errorMessage = 'Gym not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create Coach object from the queried data
      final coach = Coach.fromJson(coachData, query.docs.first.id);

      // Set the session coach (don't overwrite _currentCoach/_currentGym which are for admin)
      _sessionCoach = coach;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with email/password
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.authenticateWithEmail(email, password);
      if (result != null) {
        _currentCoach = result['coach'];
        _currentGym = result['gym'];
        await _saveAuth(_currentCoach!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign up new coach with email, password, name, and current gym code
  Future<bool> signupCoach({
    required String email,
    required String password,
    required String name,
  }) async {
    if (_currentGymCode == null) {
      _errorMessage = 'No gym code selected';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get the gym ID from the gym code
      final gymQuery = await _firestore
          .collection('gyms')
          .where('code', isEqualTo: _currentGymCode)
          .limit(1)
          .get();

      if (gymQuery.docs.isEmpty) {
        _errorMessage = 'Gym not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final gymId = gymQuery.docs.first.id;

      // Create coach account in auth service
      final result = await _authService.createCoachAccount(
        email: email,
        password: password,
        name: name,
        gymId: gymId,
      );

      if (result != null) {
        _currentCoach = result['coach'];
        _currentGym = result['gym'];
        await _saveAuth(_currentCoach!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Fetch pending coaches for current gym (admin only)
  Future<void> loadPendingCoaches() async {
    if (_currentGym == null || _currentCoach?.role != 'admin') {
      return;
    }

    try {
      _pendingCoaches =
          await _authService.getPendingCoachesForGym(_currentGym!.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Approve a coach (admin only)
  Future<void> approveCoach(String coachId) async {
    try {
      await _authService.approveCoach(coachId);
      await loadPendingCoaches();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Reject a coach (admin only)
  Future<void> rejectCoach(String coachId) async {
    try {
      await _authService.rejectCoach(coachId);
      await loadPendingCoaches();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Update selected workout for tablet display
  Future<void> setSelectedWorkout(String? workoutId) async {
    if (_currentCoach == null) return;

    try {
      await _authService.setSelectedWorkout(_currentCoach!.id, workoutId);
      _currentCoach = _currentCoach!.copyWith(currentSelectedWorkout: workoutId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Delete coach account
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentCoach == null) {
        throw Exception('No coach logged in');
      }
      await _authService.deleteAccount(_currentCoach!.id, password);
      await _clearStoredAuth();
      _currentCoach = null;
      _currentGym = null;
      _currentGymCode = null;
      _isHostMode = false;
      _hostCoachCode = null;
      _pendingCoaches = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify admin password by re-authenticating
  Future<void> verifyAdminPassword(String password) async {
    if (_currentCoach == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      await _authService.reauthenticateForAdmin(_currentCoach!.email, password);
    } catch (e) {
      throw Exception('Invalid password');
    }
  }

  // Logout
  Future<void> logout() async {
    _authService.logout();
    _currentCoach = null;
    _currentGym = null;
    _currentGymCode = null;
    _isHostMode = false;
    _hostCoachCode = null;
    _adminType = null;
    _sessionCoach = null;
    _errorMessage = null;
    _pendingCoaches = [];
    await _clearStoredAuth();
    notifyListeners();
  }

  // Set the session coach (after admin logs in)
  void setSessionCoach(Coach coach) {
    _sessionCoach = coach;
    notifyListeners();
  }

  // Clear the session coach (go back to admin view)
  void clearSessionCoach() {
    _sessionCoach = null;
    notifyListeners();
  }
}
