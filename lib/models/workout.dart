import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String gymId;
  final String coachId;
  final String name;
  final String description;
  final List<Exercise> exercises;
  final int rounds; // number of rounds to repeat
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? previewImageUrl;

  Workout({
    required this.id,
    required this.gymId,
    required this.coachId,
    required this.name,
    this.description = '',
    this.exercises = const [],
    this.rounds = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.previewImageUrl,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Get total workout duration in seconds
  int getTotalDuration() {
    int total = 0;
    for (var exercise in exercises) {
      total += exercise.duration + exercise.restAfter;
    }
    return total * rounds;
  }

  // Convert Workout to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gymId': gymId,
      'coachId': coachId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'rounds': rounds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'previewImageUrl': previewImageUrl,
    };
  }

  // Create Workout from Firestore document
  factory Workout.fromJson(Map<String, dynamic> json) {
    final exercisesList = (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return Workout(
      id: json['id'] ?? '',
      gymId: json['gymId'] ?? '',
      coachId: json['coachId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      exercises: exercisesList,
      rounds: json['rounds'] ?? 1,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previewImageUrl: json['previewImageUrl'],
    );
  }

  // Create a copy with modifications
  Workout copyWith({
    String? id,
    String? gymId,
    String? coachId,
    String? name,
    String? description,
    List<Exercise>? exercises,
    int? rounds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? previewImageUrl,
  }) {
    return Workout(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      coachId: coachId ?? this.coachId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      rounds: rounds ?? this.rounds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
    );
  }
}
