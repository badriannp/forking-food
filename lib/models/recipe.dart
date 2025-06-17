import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final int forkInCount;
  final int forkOutCount;
  final int forkingoodCount;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.forkInCount = 0,
    this.forkOutCount = 0,
    this.forkingoodCount = 0,
  });

  // Factory constructor to create a Recipe from a Firestore document
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      description: map['description'] as String,
      ingredients: List<String>.from(map['ingredients'] as List),
      instructions: List<String>.from(map['instructions'] as List),
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      forkInCount: map['forkInCount'] as int? ?? 0,
      forkOutCount: map['forkOutCount'] as int? ?? 0,
      forkingoodCount: map['forkingoodCount'] as int? ?? 0,
    );
  }

  // Convert Recipe to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt,
      'forkInCount': forkInCount,
      'forkOutCount': forkOutCount,
      'forkingoodCount': forkingoodCount,
    };
  }
} 