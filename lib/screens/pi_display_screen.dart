import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/active_workout_service.dart';
import 'dart:async';

class PiDisplayScreen extends StatefulWidget {
  final String gymId;

  PiDisplayScreen({required this.gymId, super.key}) {
    print('[PiDisplay_WIDGET] 🔵 PiDisplayScreen CONSTRUCTOR called for gym: $gymId');
  }

  @override
  State<PiDisplayScreen> createState() {
    print('[PiDisplay_WIDGET] 🔵 createState() called - creating _PiDisplayScreenState');
    return _PiDisplayScreenState();
  }
}

class _PiDisplayScreenState extends State<PiDisplayScreen> {
  late ActiveWorkoutService _workoutService;
  late Timer _updateTimer;
  DateTime? _lastStartedAt;
  DateTime? _localWorkoutStartTime; // LOCAL reference time when workout started
  String? _lastWorkoutStatus; // Track previous status to detect pause/resume
  String _currentWorkoutStatus = 'running'; // Track current status for pause check
  bool _cleanupComplete = false;
  late ValueNotifier<int> _timerNotifier; // For timer updates only
  
  // Full workout structure - loaded once at start
  List<Map<String, dynamic>> _workoutExercises = [];
  
  // Phase tracking for current exercise
  int _currentDisplayExerciseIndex = 0;
  String _currentDisplayPhase = 'Exercise'; // 'Exercise', 'Rest', or 'Ready'
  
  // Phase calculation results (updated on every timer tick)
  bool _isInRestPhase = false;
  bool _isInReadyPhase = false;
  int _exerciseTimeRemaining = 0;
  int _restTimeRemaining = 0;
  String _exerciseName = 'Unknown';
  String _nextExerciseName = 'Unknown'; // For display during ready phase
  int _exerciseDuration = 0;
  int _restDuration = 0;
  int _totalElapsedSeconds = 0;
  int _readyCountdownNumber = 0; // 10-1 for countdown, 0 for "ROUND START!"
  
  // Long press tracking for quick stop
  DateTime? _longPressStart;
  bool _isHoldingTimer = false;
  late ValueNotifier<double> _holdProgressNotifier; // 0.0 to 1.0 for visual feedback

  @override
  void initState() {
    super.initState();
    print('[PiDisplay] ✅ PiDisplayScreen initialized for gym: ${widget.gymId}');
    _workoutService = ActiveWorkoutService();
    _timerNotifier = ValueNotifier<int>(0);
    _holdProgressNotifier = ValueNotifier<double>(0.0);
    _performCleanup();
    // Update timer every 100ms (but DON'T call setState - just update ValueNotifier)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _timerNotifier.value++; // This doesn't trigger full widget rebuild
    });
  }

  Future<void> _performCleanup() async {
    await _cleanupStuckWorkouts();
    if (mounted) {
      setState(() {
        _cleanupComplete = true;
      });
    }
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _timerNotifier.dispose();
    _holdProgressNotifier.dispose();
    super.dispose();
  }

  Future<void> _cleanupStuckWorkouts() async {
    try {
      print('[PiDisplay] 🧹 CLEANUP: Scanning for stuck/orphaned workouts...');
      
      final workoutData = await _workoutService.getActiveWorkout(widget.gymId);

      if (workoutData != null) {
        final startedAt = workoutData['startedAt'] as Timestamp?;
        final status = workoutData['status'] as String? ?? 'unknown';

        if (startedAt != null) {
          final now = DateTime.now();
          final workoutStartTime = startedAt.toDate();
          final elapsedSeconds = now.difference(workoutStartTime).inSeconds;

          print('[PiDisplay] Found workout: status=$status, age=${elapsedSeconds}s');

          // If workout has been running for more than 24 hours, it's definitely stuck
          const maxWorkoutSeconds = 24 * 60 * 60; // 24 hours max - allows workouts spanning multiple days
          
          if (elapsedSeconds > maxWorkoutSeconds) {
            print('[PiDisplay] ⚠️  STUCK WORKOUT DETECTED - Age: ${elapsedSeconds}s (${elapsedSeconds ~/ 3600}h ${(elapsedSeconds % 3600) ~/ 60}m)');
            print('[PiDisplay] 🗑️  DELETING STUCK WORKOUT...');
            
            // Force delete - try multiple times if needed
            int deleteAttempts = 0;
            bool deleteSuccessful = false;
            
            while (deleteAttempts < 3 && !deleteSuccessful) {
              try {
                deleteAttempts++;
                print('[PiDisplay] Delete attempt $deleteAttempts...');
                await _workoutService.stopWorkout(widget.gymId);
                
                // Wait and verify deletion
                await Future.delayed(const Duration(milliseconds: 400));
                final verifyData = await _workoutService.getActiveWorkout(widget.gymId);
                
                if (verifyData == null) {
                  print('[PiDisplay] ✅ Stuck workout successfully deleted and verified GONE');
                  deleteSuccessful = true;
                } else {
                  print('[PiDisplay] ⚠️  Delete attempt $deleteAttempts: Document still exists, retrying...');
                }
              } catch (deleteError) {
                print('[PiDisplay] ❌ Delete attempt $deleteAttempts error: $deleteError');
              }
            }
            
            if (!deleteSuccessful) {
              print('[PiDisplay] ❌ Failed to delete stuck workout after $deleteAttempts attempts');
            }
          } else {
            print('[PiDisplay] ℹ️  Workout age is OK (${elapsedSeconds}s), fresh enough to keep');
          }
        }
      } else {
        print('[PiDisplay] ✅ No active workout - clean state');
      }
    } catch (e) {
      print('[PiDisplay] ❌ Error during cleanup: $e');
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Updates phase information based on elapsed time
  /// Call this on every timer tick to keep phase detection live
  void _updatePhase() {
    // Skip all phase updates if paused - display stays frozen
    if (_currentWorkoutStatus == 'paused') {
      return;
    }
    
    // Calculate total elapsed seconds
    _totalElapsedSeconds = 0;
    if (_localWorkoutStartTime != null) {
      final now = DateTime.now();
      _totalElapsedSeconds = now.difference(_localWorkoutStartTime!).inSeconds;
    }

    // Walk through all exercises to determine current position
    int accumulatedTime = 0;
    bool foundPhase = false;

    print('[PiDisplay] 📊 [TIMER] Elapsed: ${_totalElapsedSeconds}s, exercises loaded: ${_workoutExercises.length}');

    for (int i = 0; i < _workoutExercises.length && !foundPhase; i++) {
      final exercise = _workoutExercises[i];
      final exDuration = exercise['duration'] as int? ?? 0;
      final exName = exercise['name'] as String? ?? 'Exercise';
      final isRestExercise = exName == 'Rest';

      final phaseEnd = accumulatedTime + exDuration;

      print('[PiDisplay] [TIMER] Ex[$i] "$exName" (${isRestExercise ? 'REST' : 'EXERCISE'}): elapsed=$_totalElapsedSeconds, window=[$accumulatedTime-$phaseEnd]');

      // Check if we're in this exercise/rest
      if (_totalElapsedSeconds < phaseEnd) {
        _currentDisplayExerciseIndex = i;
        _exerciseName = exName;
        _exerciseDuration = exDuration;
        
        if (isRestExercise) {
          // This is a REST exercise
          _restDuration = exDuration;
          _restTimeRemaining = (phaseEnd - _totalElapsedSeconds).clamp(0, exDuration);
          
          // Check if we're in the final 10 seconds of rest (READY phase)
          if (_restTimeRemaining <= 10 && _restTimeRemaining > 0) {
            _currentDisplayPhase = 'Ready';
            _isInReadyPhase = true;
            _isInRestPhase = false;
            
            // Calculate ready countdown number (10-1, then 0 for ROUND START)
            _readyCountdownNumber = _restTimeRemaining;
            if (_readyCountdownNumber > 10) _readyCountdownNumber = 10;
            
            // Get the next exercise name for display
            _nextExerciseName = _getNextExerciseName() ?? 'Next Exercise';
            
            print('[PiDisplay] [TIMER] 🟡 IN READY PHASE: countdown=$_readyCountdownNumber, next="$_nextExerciseName"');
          } else if (_restTimeRemaining > 10) {
            // Still in normal rest phase
            _currentDisplayPhase = 'Rest';
            _isInRestPhase = true;
            _isInReadyPhase = false;
            print('[PiDisplay] [TIMER] 🔴 IN REST $i: "$exName" - ${_restTimeRemaining}s remaining');
          }
        } else {
          // This is a regular exercise
          _currentDisplayPhase = 'Exercise';
          _isInRestPhase = false;
          _isInReadyPhase = false;
          _restDuration = 0;
          _exerciseTimeRemaining = (phaseEnd - _totalElapsedSeconds).clamp(0, exDuration);
          print('[PiDisplay] [TIMER] ✅ IN EXERCISE $i: "$exName" - ${_exerciseTimeRemaining}s remaining');
        }
        
        foundPhase = true;
      }

      accumulatedTime = phaseEnd;
    }

    // If we didn't find a phase, workout is over
    if (!foundPhase) {
      print('[PiDisplay] [TIMER] ✅ WORKOUT COMPLETE - All exercises done (total elapsed: ${_totalElapsedSeconds}s, accumulated: ${accumulatedTime}s)');
      _exerciseName = 'Workout Complete!';
      _exerciseDuration = 0;
      _restDuration = 0;
      _isInRestPhase = false;
      _isInReadyPhase = false;
    }
  }

  /// Finds the next non-rest exercise from current position
  String? _getNextExerciseName() {
    for (int i = _currentDisplayExerciseIndex + 1; i < _workoutExercises.length; i++) {
      final exercise = _workoutExercises[i];
      final name = exercise['name'] as String? ?? '';
      if (name != 'Rest') {
        return name;
      }
    }
    return null; // No more exercises
  }

  /// Calculates dynamic font size based on text length
  /// Short text (few chars) gets larger font, long text gets smaller
  double _getDynamicFontSize(String text) {
    final length = text.length;
    // Scale: 1-7 chars → 96px, 8-20 chars → 64px, 21+ chars → 48px
    if (length <= 7) return 96;
    if (length <= 15) return 80;
    if (length <= 25) return 64;
    if (length <= 35) return 56;
    return 48;
  }

  void _onTimerLongPressStart() {
    print('[PiDisplay] 👉 Timer long press START - hold for 3 seconds to stop workout');
    _longPressStart = DateTime.now();
    _isHoldingTimer = true;
    _holdProgressNotifier.value = 0.0;
    
    // Periodic check every 100ms
    Timer.periodic(const Duration(milliseconds: 100), (holdTimer) {
      if (!_isHoldingTimer) {
        print('[PiDisplay] Release detected, canceling hold timer');
        holdTimer.cancel();
        _holdProgressNotifier.value = 0.0;
        return;
      }
      
      final elapsed = DateTime.now().difference(_longPressStart!).inMilliseconds;
      final progress = (elapsed / 3000).clamp(0.0, 1.0); // 3000ms = 3 seconds
      
      _holdProgressNotifier.value = progress;
      
      if (progress >= 1.0) {
        print('[PiDisplay] ⏱️  3 SECOND HOLD DETECTED - STOPPING WORKOUT');
        holdTimer.cancel();
        _onTimerLongPressDone();
      }
    });
  }

  void _onTimerLongPressEnd() {
    print('[PiDisplay] 🖐️  Timer long press END');
    _isHoldingTimer = false;
  }

  Future<void> _onTimerLongPressDone() async {
    _isHoldingTimer = false;
    _holdProgressNotifier.value = 0.0;
    
    try {
      print('[PiDisplay] 🛑 EXECUTING HARD STOP - Deleting workout and clearing local data');
      await _workoutService.stopWorkout(widget.gymId);
      
      // Verify deletion
      await Future.delayed(const Duration(milliseconds: 400));
      final verifyData = await _workoutService.getActiveWorkout(widget.gymId);
      
      if (verifyData == null) {
        print('[PiDisplay] ✅ Workout successfully stopped and deleted');
        _lastStartedAt = null;
        _localWorkoutStartTime = null; // Reset local timer
        _currentDisplayExerciseIndex = 0;
        _currentDisplayPhase = 'Exercise';
        _workoutExercises = [];
      } else {
        print('[PiDisplay] ⚠️  Workout still exists after stop, retrying...');
        // Retry stop
        await _workoutService.stopWorkout(widget.gymId);
      }
    } catch (e) {
      print('[PiDisplay] ❌ Error stopping workout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _cleanupComplete
          ? StreamBuilder<Map<String, dynamic>?>(
              stream: _workoutService.getActiveWorkoutStream(widget.gymId),
              builder: (context, snapshot) {
                // Log stream state for debugging
                print('[PiDisplay] 🔌 Stream state: ${snapshot.connectionState}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('[PiDisplay] ⏳ Stream waiting for data...');
                }
                if (snapshot.hasError) {
                  print('[PiDisplay] ❌ Stream error: ${snapshot.error}');
                }
                
                // No active workout - display SPRTN STUDIO logo
                if (!snapshot.hasData || snapshot.data == null) {
                  print('[PiDisplay] 📭 No active workout data received');
                  _lastStartedAt = null;
                  _localWorkoutStartTime = null; // Reset local timer
                  _currentDisplayExerciseIndex = 0;
                  _currentDisplayPhase = 'Exercise';
                  _workoutExercises = [];
                  return Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          'STUDIO',
                          textScaleFactor: 1.0,
                          style: GoogleFonts.barlow(
                            fontSize: 140,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        Positioned(
                          left: 5,
                          top: -6,
                          child: Text(
                            'SPRTN',
                            textScaleFactor: 1.0,
                            style: GoogleFonts.barlow(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final workoutData = snapshot.data!;
                print('[PiDisplay] 📥 Received workout data from stream');
                final startedAt = workoutData['startedAt'] as Timestamp?;
                final workoutName = workoutData['workoutName'] ?? 'Unknown';
                print('[PiDisplay] Workout: $workoutName, Started at: $startedAt');

                // Note: No safety check here - startWorkout() already ensures fresh data
                // If a document exists, trust that it's valid

                final currentPhaseStartTime =
              workoutData['currentPhaseStartTime'] as Timestamp?;
          final currentExerciseIndex =
              workoutData['currentExerciseIndex'] as int? ?? 0;
          final exercises =
              (workoutData['exercises'] as List<dynamic>?) ?? [];
          final status = workoutData['status'] as String? ?? 'unknown';
          
          // Capture current status for timer pause logic
          _currentWorkoutStatus = status;

          print('[PiDisplay] ✅ Exercises loaded from stream: ${exercises.length}');
          for (int i = 0; i < exercises.length; i++) {
            final ex = exercises[i];
            print('[PiDisplay]   [$i] name="${ex['name']}", duration=${ex['duration']}, restAfter=${ex['restAfter']}');
          }

          print('[PiDisplay] ══════════════════════════════════════');
          print('[PiDisplay] Status: $status');
          print('[PiDisplay] Exercise index: $currentExerciseIndex / ${exercises.length}');
          print('[PiDisplay] Current phase started at: $currentPhaseStartTime');
          print('[PiDisplay] ══════════════════════════════════════');

          // Detect fresh workout start
          // Only reset if we DON'T have exercises loaded yet (brand new workout)
          // If we already have exercises, this is just a status change (pause/resume), not a new workout
          if (startedAt != null && _lastStartedAt != startedAt.toDate() && _workoutExercises.isEmpty) {
            _lastStartedAt = startedAt.toDate();
            _localWorkoutStartTime = DateTime.now();
            _currentDisplayExerciseIndex = 0;
            _currentDisplayPhase = 'Exercise';
            _isInRestPhase = false;
            _isInReadyPhase = false;
            _nextExerciseName = 'Unknown';
            _readyCountdownNumber = 0;
            
            // CRITICAL: Load entire workout structure
            _workoutExercises = (exercises.cast<Map<String, dynamic>>()).toList();
            print('[PiDisplay] 🎬 Fresh workout detected!');
            print('[PiDisplay] 📋 Loading full workout: ${_workoutExercises.length} exercises');
            for (int i = 0; i < _workoutExercises.length; i++) {
              final ex = _workoutExercises[i];
              final name = ex['name'] ?? 'Unknown';
              final duration = ex['duration'] ?? 0;
              final rest = ex['restAfter'] ?? 0;
              print('[PiDisplay]   [$i] "$name" - duration: ${duration}s, rest AFTER: ${rest}s');
            }
            print('[PiDisplay] ⏱️  Starting local timer - will calculate all phases locally');
          } else if (_workoutExercises.isNotEmpty && startedAt != null && _lastStartedAt != startedAt.toDate()) {
            // Workout is already loaded, just update the timestamp for tracking
            final wasResuming = _lastWorkoutStatus == 'paused' && status == 'running';
            if (wasResuming && _localWorkoutStartTime != null) {
              final pausedElapsedSeconds = (workoutData['pausedElapsedSeconds'] as int?) ?? 0;
              
              // Calculate which exercise we should be in based on pausedElapsedSeconds
              // by walking through the workout structure
              int accumulatedTime = 0;
              int calculatedExerciseIndex = 0;
              
              for (int i = 0; i < _workoutExercises.length; i++) {
                final exercise = _workoutExercises[i];
                final duration = (exercise['duration'] as int?) ?? 0;
                final restAfter = (exercise['restAfter'] as int?) ?? 0;
                
                // Check if pausedElapsedSeconds falls in this exercise
                if (pausedElapsedSeconds < accumulatedTime + duration) {
                  calculatedExerciseIndex = i;
                  break;
                }
                accumulatedTime += duration + restAfter;
              }
              
              _currentDisplayExerciseIndex = calculatedExerciseIndex;
              
              // Adjust local timer based on how much the service's startedAt changed
              final timeSinceLastStarted = DateTime.now().difference(_localWorkoutStartTime!).inSeconds;
              final drift = timeSinceLastStarted - pausedElapsedSeconds;
              _localWorkoutStartTime = _localWorkoutStartTime!.add(Duration(seconds: drift));
              print('[PiDisplay] ▶️ RESUMED - calculated exercise index $calculatedExerciseIndex from ${pausedElapsedSeconds}s elapsed, adjusted timing by ${drift}s');
            }
            _lastStartedAt = startedAt.toDate();
            print('[PiDisplay] ⏸️ Status/timing changed (pause/resume detected), but keeping current state');
          }
          
          // Update status tracker
          _lastWorkoutStatus = status;

          // Phase detection now happens on every timer tick via _updatePhase()
          // This is called from within the ValueListenableBuilder below

          return Stack(
            children: [
              // Main content - wrapped in Positioned.fill so it layers correctly with overlay
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Main Timer - wrapped in ValueListenableBuilder for smooth updates
                        ValueListenableBuilder<int>(
                          valueListenable: _timerNotifier,
                          builder: (context, _, __) {
                            // UPDATE PHASE on every timer tick (every 100ms)
                            _updatePhase();
                            
                            int displaySeconds = 0;
                            
                            // Show appropriate timer based on phase
                            if (_isInRestPhase || _isInReadyPhase) {
                              // During rest or ready phase, show rest countdown to 0
                              displaySeconds = _restTimeRemaining;
                            } else {
                              // During exercise, show time remaining in THIS exercise
                              displaySeconds = _exerciseTimeRemaining;
                            }
                            // When paused, these values stay frozen (updatePhase returns early)
                          
                          return Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Timer with hold progress
                                  ValueListenableBuilder<double>(
                                    valueListenable: _holdProgressNotifier,
                                    builder: (context, holdProgress, _) {
                                      return GestureDetector(
                                        onLongPressStart: (_) => _onTimerLongPressStart(),
                                        onLongPressEnd: (_) => _onTimerLongPressEnd(),
                                        onLongPressCancel: () => _onTimerLongPressEnd(),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Hold progress ring (only visible when holding)
                                            if (holdProgress > 0)
                                              CustomPaint(
                                                painter: HoldProgressPainter(holdProgress),
                                                size: const Size(200, 200),
                                              ),
                                            // Timer text - shows MM:SS during normal phases, just number during ready countdown
                                            if (_isInReadyPhase)
                                              AnimatedScale(
                                                scale: 1.2,
                                                duration: const Duration(milliseconds: 400),
                                                child: Text(
                                                  _readyCountdownNumber.toString(),
                                                  style: GoogleFonts.barlow(
                                                    fontSize: 200,
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(0xFFEF4444),
                                                  ),
                                                ),
                                              )
                                            else
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                textBaseline: TextBaseline.alphabetic,
                                                children: [
                                                  // Minutes tens digit
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      (displaySeconds ~/ 60).toString().padLeft(2, '0')[0],
                                                      style: GoogleFonts.barlow(
                                                        fontSize: 200,
                                                        fontWeight: FontWeight.w900,
                                                        color: (_isInRestPhase || _isInReadyPhase) ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                  // Minutes ones digit
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      (displaySeconds ~/ 60).toString().padLeft(2, '0')[1],
                                                      style: GoogleFonts.barlow(
                                                        fontSize: 200,
                                                        fontWeight: FontWeight.w900,
                                                        color: (_isInRestPhase || _isInReadyPhase) ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                  // Colon - centered
                                                  Text(
                                                    ':',
                                                    style: GoogleFonts.barlow(
                                                      fontSize: 200,
                                                      fontWeight: FontWeight.w900,
                                                      color: (_isInRestPhase || _isInReadyPhase) ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                    ),
                                                  ),
                                                  // Seconds tens digit
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      (displaySeconds % 60).toString().padLeft(2, '0')[0],
                                                      style: GoogleFonts.barlow(
                                                        fontSize: 200,
                                                        fontWeight: FontWeight.w900,
                                                        color: (_isInRestPhase || _isInReadyPhase) ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                  // Seconds ones digit
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      (displaySeconds % 60).toString().padLeft(2, '0')[1],
                                                      style: GoogleFonts.barlow(
                                                        fontSize: 200,
                                                        fontWeight: FontWeight.w900,
                                                        color: (_isInRestPhase || _isInReadyPhase) ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 40),
                                  
                                  // Current Round/Exercise Info (now inside outer builder for sync)
                                  if (_currentDisplayPhase == 'Ready')
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'UP NEXT:',
                                          style: GoogleFonts.barlow(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _nextExerciseName,
                                          style: GoogleFonts.barlow(
                                            fontSize: 64,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      _currentDisplayPhase == 'Rest' ? 'REST' : _exerciseName,
                                      style: GoogleFonts.barlow(
                                        fontSize: _currentDisplayPhase == 'Rest' 
                                          ? 96 
                                          : _getDynamicFontSize(_exerciseName),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      // Exercise info is now inside ValueListenableBuilder for sync
                    ],
                  ),
                ),
              ),
              ),
              // UP NEXT box - fixed to top right corner (updates with timer)
              if (!_isInRestPhase && !_isInReadyPhase && _getNextExerciseName() != null)
                ValueListenableBuilder<int>(
                  valueListenable: _timerNotifier,
                  builder: (context, _value, __) {
                    return Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UP NEXT',
                              style: GoogleFonts.barlow(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getNextExerciseName() ?? '',
                              style: GoogleFonts.barlow(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              // REST OVERLAY - shown when in rest phase (full screen coverage)
              if (_isInRestPhase)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.95),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'REST',
                            style: GoogleFonts.barlow(
                              fontSize: 60,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ValueListenableBuilder<int>(
                            valueListenable: _timerNotifier,
                            builder: (context, _value, __) {
                              return Text(
                                _formatTime(_restTimeRemaining),
                                style: GoogleFonts.barlow(
                                  fontSize: 140,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFEF4444),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Get ready for the next round',
                            style: GoogleFonts.barlow(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // READY COUNTDOWN OVERLAY - hidden for now, rest timer continues to display
            ],
          );
        },
      )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Initializing Display...',
                    style: GoogleFonts.barlow(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cleaning up old workouts...',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom painter to draw the hold progress ring
class HoldProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  HoldProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final radius = (size.width / 2) - (strokeWidth / 2);
    final center = Offset(size.width / 2, size.height / 2);

    // Background ring (light gray)
    final backgroundPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring (red - indicates danger/stop)
    final progressPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (progress * 2 * 3.14159); // progress * 2π
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(HoldProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
