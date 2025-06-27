import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String id;
  final String displayName;
  final String? photoURL;
  final String? email;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserData({
    required this.id,
    required this.displayName,
    this.photoURL,
    this.email,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserData.fromMap(Map<String, dynamic> map, String id) {
    return UserData(
      id: id,
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      email: map['email'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoURL': photoURL,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserData copyWith({
    String? displayName,
    String? photoURL,
    String? email,
  }) {
    return UserData(
      id: id,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      email: email ?? this.email,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
} 