import 'package:cloud_firestore/cloud_firestore.dart';

class Coach {
  final String id;
  final String name;
  final String email;
  final String gymId; // Which gym this coach belongs to
  final String role; // 'admin' or 'coach'
  final String coachCode; // 4-digit unique code for this coach
  final DateTime createdAt;
  final String? profileImageUrl;
  final String? currentSelectedWorkout;
  final bool isApproved; // Whether admin has approved this coach to access the gym
  final String status; // 'pending', 'approved', 'rejected'

  Coach({
    required this.id,
    required this.name,
    required this.email,
    required this.gymId,
    required this.coachCode,
    this.role = 'coach',
    DateTime? createdAt,
    this.profileImageUrl,
    this.currentSelectedWorkout,
    this.isApproved = false,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Coach to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gymId': gymId,
      'role': role,
      'coachCode': coachCode,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
      'currentSelectedWorkout': currentSelectedWorkout,
      'isApproved': isApproved,
      'status': status,
    };
  }

  // Create Coach from Firestore document with document ID
  factory Coach.fromJson(Map<String, dynamic> json, String docId) {
    return Coach(
      id: docId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gymId: json['gymId'] ?? '',
      coachCode: json['coachCode'] ?? '',
      role: json['role'] ?? 'coach',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: json['profileImageUrl'],
      currentSelectedWorkout: json['currentSelectedWorkout'],
      isApproved: json['isApproved'] ?? false,
      status: json['status'] ?? 'pending',
    );
  }

  // Create a copy with modifications
  Coach copyWith({
    String? id,
    String? name,
    String? email,
    String? gymId,
    String? role,
    String? coachCode,
    DateTime? createdAt,
    String? profileImageUrl,
    String? currentSelectedWorkout,
    bool? isApproved,
    String? status,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gymId: gymId ?? this.gymId,
      role: role ?? this.role,
      coachCode: coachCode ?? this.coachCode,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentSelectedWorkout: currentSelectedWorkout ?? this.currentSelectedWorkout,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
    );
  }
}
