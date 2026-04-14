import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../services/workout_service.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import 'phone_my_workouts_screen.dart';
import 'phone_settings_screen.dart';
import 'phone_create_workout_screen.dart';

class PhoneHomeScreen extends StatefulWidget {
  const PhoneHomeScreen({super.key});

  @override
  State<PhoneHomeScreen> createState() => _PhoneHomeScreenState();
}

class _PhoneHomeScreenState extends State<PhoneHomeScreen> {
  int _selectedTab = 0;
  String? _pressedNavButton; // Track which nav button is pressed

  void _openCreateWorkoutModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhoneCreateWorkoutScreen(),
      ),
    );
  }

  void _showCoachCode(BuildContext context, String? coachCode) {
    // Do nothing - the code is already visible in the top right
  }


  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isPressed,
  }) {
    final iconColor = isSelected ? const Color(0xFF3B82F6) : Colors.black38;
    final textColor = isSelected ? const Color(0xFF3B82F6) : Colors.black38;
    
    return Transform.scale(
      scale: isPressed ? 0.85 : 1.0,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.barlow(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  _selectedTab == 0 ? 'My Workouts' : 'Settings',
                  style: GoogleFonts.barlow(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final coachCode = authProvider.currentCoach?.coachCode;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () => _showCoachCode(context, coachCode),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.key,
                              color: const Color(0xFF3B82F6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              coachCode ?? '----',
                              style: GoogleFonts.barlow(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedTab,
          children: const [
            PhoneMyWorkoutsScreen(),
            PhoneSettingsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Workouts button
              GestureDetector(
                onTapDown: (_) => setState(() => _pressedNavButton = 'workouts'),
                onTapUp: (_) => setState(() => _pressedNavButton = null),
                onTapCancel: () => setState(() => _pressedNavButton = null),
                onTap: () => setState(() => _selectedTab = 0),
                child: _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Workouts',
                  isSelected: _selectedTab == 0,
                  isPressed: _pressedNavButton == 'workouts',
                ),
              ),
              // Plus button (centered, prominent)
              GestureDetector(
                onTapDown: (_) => setState(() => _pressedNavButton = 'plus'),
                onTapUp: (_) => setState(() => _pressedNavButton = null),
                onTapCancel: () => setState(() => _pressedNavButton = null),
                onTap: () => _openCreateWorkoutModal(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Transform.scale(
                        scale: _pressedNavButton == 'plus' ? 0.85 : 1.0,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button
              GestureDetector(
                onTapDown: (_) => setState(() => _pressedNavButton = 'settings'),
                onTapUp: (_) => setState(() => _pressedNavButton = null),
                onTapCancel: () => setState(() => _pressedNavButton = null),
                onTap: () => setState(() => _selectedTab = 1),
                child: _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _selectedTab == 1,
                  isPressed: _pressedNavButton == 'settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal widget extracted from PhoneCreateScreen
class _CreateWorkoutModal extends StatefulWidget {
  const _CreateWorkoutModal();

  @override
  State<_CreateWorkoutModal> createState() => _CreateWorkoutModalState();
}

class _CreateWorkoutModalState extends State<_CreateWorkoutModal> {
  late WorkoutService _workoutService;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _currentStep = 1;
  int _nextItemId = 0; // Counter for generating unique IDs
  final List<Map<String, dynamic>> _items = []; // List to store rounds and rests
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _workoutService = WorkoutService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (_currentStep == 1) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a workout name')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      var hasRound = _items.any((item) => item['type'] == 'round');
      if (!hasRound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one round')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _showAddRoundDialog() {
    final roundDurationController = TextEditingController(text: '3:00');
    final roundFocusController = TextEditingController();
    final scrollController = ScrollController();
    final focusNode = FocusNode();
    
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
    
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
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Round ${_getNextRoundNumber()}',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roundDurationController,
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
                focusNode: focusNode,
                controller: roundFocusController,
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
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  focusNode.dispose();
                  scrollController.dispose();
                  setState(() {
                    _items.add({
                      'id': _nextItemId++,
                      'type': 'round',
                      'duration': roundDurationController.text.isEmpty ? '3:00' : roundDurationController.text,
                      'focus': roundFocusController.text,
                    });
                  });
                  Navigator.pop(context);
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

  void _showAddRestDialog() {
    final restDurationController = TextEditingController(text: '1:00');
    final scrollController = ScrollController();
    
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
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Rest ${_getNextRestNumber()}',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: restDurationController,
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
                  scrollController.dispose();
                  setState(() {
                    _items.add({
                      'id': _nextItemId++,
                      'type': 'rest',
                      'duration': restDurationController.text.isEmpty ? '1:00' : restDurationController.text,
                    });
                  });
                  Navigator.pop(context);
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

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  int _getNextRoundNumber() {
    int count = 0;
    for (var item in _items) {
      if (item['type'] == 'round') count++;
    }
    return count + 1;
  }

  int _getNextRestNumber() {
    int count = 0;
    for (var item in _items) {
      if (item['type'] == 'rest') count++;
    }
    return count + 1;
  }

  Widget _buildItemCard(Map<String, dynamic> item, int globalIndex) {
    // Calculate the actual round/rest number based on type
    int roundNumber = 0;
    int restNumber = 0;
    
    for (int i = 0; i <= globalIndex; i++) {
      if (_items[i]['type'] == 'round') {
        roundNumber++;
      } else if (_items[i]['type'] == 'rest') {
        restNumber++;
      }
    }
    
    final isRound = item['type'] == 'round';
    final color = isRound ? const Color(0xFF3B82F6) : Colors.orange;
    
    return Column(
      children: [
        Container(
          key: ValueKey(item['id']),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isRound ? 'Round' : 'Rest'} ${isRound ? roundNumber : restNumber}',
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${item['duration'] ?? (isRound ? '3:00' : '1:00')}',
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRound && (item['focus']?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Focus: ${item['focus']}',
                        style: GoogleFonts.barlow(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _removeItem(globalIndex),
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          Text(
            'Step 1 of 3: Basic Info',
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B82F6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Workout Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Workout Name',
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
          const SizedBox(height: 16),
          // Description (Optional)
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
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
            maxLines: 3,
          ),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          Text(
            'Step 2 of 3: Rounds & Exercises',
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B82F6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Items list with drag and drop
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No rounds or rests added yet',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              children: [
                for (int index = 0; index < _items.length; index++)
                  ReorderableDragStartListener(
                    key: ValueKey(_items[index]['id']),
                    index: index,
                    child: _buildItemCard(_items[index], index),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddRoundDialog,
                icon: const Icon(Icons.add),
                label: Text(
                  'Add Round',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showAddRestDialog,
                icon: const Icon(Icons.add),
                label: Text(
                  'Add Rest',
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Step 3: Summary
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          Text(
            'Step 3 of 3: Review & Create',
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B82F6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Summary card
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Summary',
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Name', _nameController.text),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Description', _descriptionController.text.isEmpty ? '(None)' : _descriptionController.text),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Total Items', _items.length.toString()),
                      const SizedBox(height: 16),
                      Text(
                        'Boxing Circuit:',
                        style: GoogleFonts.barlow(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isRound = item['type'] == 'round';
                  
                  // Calculate actual round/rest numbers
                  int roundNumber = 0;
                  int restNumber = 0;
                  for (int i = 0; i <= entry.key; i++) {
                    if (_items[i]['type'] == 'round') {
                      roundNumber++;
                    } else if (_items[i]['type'] == 'rest') restNumber++;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRound ? Colors.blue.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isRound ? 'Round' : 'Rest'} ${isRound ? roundNumber : restNumber}',
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${item['duration'] ?? (isRound ? '3:00' : '1:00')}',
                          style: GoogleFonts.barlow(
                            fontSize: 11,
                            color: isRound ? const Color(0xFF3B82F6) : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isRound && (item['focus']?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Focus: ${item['focus']}',
                            style: GoogleFonts.barlow(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreateWorkout() async {
    // Get context data before async operations
    final authProvider = context.read<AuthProvider>();
    final currentGym = authProvider.currentGym;
    final currentCoach = authProvider.currentCoach;

    if (currentGym == null || currentCoach == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Gym or Coach not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Sync AuthService with AuthProvider's data
    _workoutService.syncAuthState(currentCoach, currentGym);

    setState(() => _isCreating = true);

    try {
      // Convert items to exercises
      List<Exercise> exercises = [];
      for (var item in _items) {
        if (item['type'] == 'round') {
          // Parse duration (e.g., "3:00" -> 180 seconds, or "3" -> 180 seconds)
          final durationStr = item['duration'] as String? ?? '3:00';
          int duration = 0;
          
          if (durationStr.contains(':')) {
            final parts = durationStr.split(':');
            final minutes = int.tryParse(parts[0]) ?? 3;
            final seconds = int.tryParse(parts[1]) ?? 0;
            duration = minutes * 60 + seconds;
          } else {
            final minutes = int.tryParse(durationStr) ?? 3;
            duration = minutes * 60;
          }

          exercises.add(
            Exercise(
              id: const Uuid().v4(),
              name: item['focus'] ?? 'Round',
              duration: duration,
              restAfter: 0,
            ),
          );
        }
      }

      final workout = Workout(
        id: const Uuid().v4(),
        gymId: currentGym.id,
        coachId: currentCoach.id,
        name: _nameController.text,
        description: _descriptionController.text,
        exercises: exercises,
        rounds: 1,
      );

      await _workoutService.createWorkout(workout);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(24).copyWith(bottom: 24 + keyboardHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Workout',
                    style: GoogleFonts.barlow(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Dynamic step content
              _buildStepContent(),
              const SizedBox(height: 32),
              // Button row
              Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating
                          ? null
                          : (_currentStep == 3 ? _handleCreateWorkout : _handleNextStep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentStep == 3 ? 'Create' : 'Next',
                              style: GoogleFonts.barlow(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
