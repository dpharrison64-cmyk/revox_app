class Gym {
  final String id;
  final String name;
  final String location;
  final String ownerId; // Coach ID of the gym owner
  final DateTime createdAt;
  final String code; // Unique code for coaches to join
  final String subscriptionLevel; // 'free', 'pro', 'enterprise'
  final bool isActive;
  final String? primaryColor; // Hex color code for the gym (e.g., '#8b0000')

  Gym({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.createdAt,
    required this.code,
    this.subscriptionLevel = 'free',
    this.isActive = true,
    this.primaryColor,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'code': code,
      'subscriptionLevel': subscriptionLevel,
      'isActive': isActive,
      'primaryColor': primaryColor,
    };
  }

  // Create from Firestore document
  factory Gym.fromJson(Map<String, dynamic> json, String docId) {
    return Gym(
      id: docId,
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      ownerId: json['ownerId'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      code: json['code'] ?? '',
      subscriptionLevel: json['subscriptionLevel'] ?? 'free',
      isActive: json['isActive'] ?? true,
      primaryColor: json['primaryColor'],
    );
  }

  // Copy with updates
  Gym copyWith({
    String? id,
    String? name,
    String? location,
    String? ownerId,
    DateTime? createdAt,
    String? code,
    String? subscriptionLevel,
    bool? isActive,
  }) {
    return Gym(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      code: code ?? this.code,
      subscriptionLevel: subscriptionLevel ?? this.subscriptionLevel,
      isActive: isActive ?? this.isActive,
    );
  }
}
