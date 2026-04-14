class Exercise {
  final String id;
  final String name;
  final String description;
  final int duration; // in seconds
  final int reps;
  final int restAfter; // in seconds
  final String? imageUrl;

  Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.duration = 0,
    this.reps = 0,
    this.restAfter = 0,
    this.imageUrl,
  });

  // Convert Exercise to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'reps': reps,
      'restAfter': restAfter,
      'imageUrl': imageUrl,
    };
  }

  // Create Exercise from Firestore document
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      reps: json['reps'] ?? 0,
      restAfter: json['restAfter'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }

  // Create a copy with modifications
  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    int? duration,
    int? reps,
    int? restAfter,
    String? imageUrl,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      reps: reps ?? this.reps,
      restAfter: restAfter ?? this.restAfter,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
