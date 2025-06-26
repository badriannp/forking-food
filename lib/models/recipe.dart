import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Represents a single step in the cooking process.
/// It can contain a description and an optional media file (image).
class InstructionStep {
  String description;
  File? localMediaFile; // Used for local form state. Will be uploaded to get a URL.
  String? mediaUrl; // URL from Firebase Storage for displaying images

  InstructionStep({
    required this.description,
    this.localMediaFile,
    this.mediaUrl,
  });
}

/// Represents a complete recipe.
class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final List<InstructionStep> instructions; // Changed from List<String>
  final Duration totalEstimatedTime;       // New field
  final List<String> tags;                 // New field: e.g., ['pasta', 'vegetarian', 'quick']
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final int forkInCount;    // Likes/Fork in count
  final int forkOutCount;   // Dislikes/Fork out count
  final int forkingoodCount; // Super likes (future feature)
  final List<String> dietaryCriteria;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.totalEstimatedTime,
    required this.tags,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.forkInCount = 0,
    this.forkOutCount = 0,
    this.forkingoodCount = 0,
    required this.dietaryCriteria,
  });

  // Factory constructor to create a Recipe from a Firestore document
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      description: map['description'] as String,
      ingredients: List<String>.from(map['ingredients'] as List),
      instructions: List<InstructionStep>.from(
        map['instructions']?.map((i) => InstructionStep(
          description: i['description'] as String,
          mediaUrl: i['mediaUrl'] as String?,
        )) ?? [],
      ),
      totalEstimatedTime: Duration(seconds: map['totalEstimatedTime'] as int? ?? 0),
      tags: List<String>.from(map['tags'] as List),
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      forkInCount: map['forkInCount'] as int? ?? 0,
      forkOutCount: map['forkOutCount'] as int? ?? 0,
      forkingoodCount: map['forkingoodCount'] as int? ?? 0,
      dietaryCriteria: List<String>.from(map['dietaryCriteria'] ?? []),
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
      'instructions': instructions.map((i) => {
        'description': i.description,
        'mediaUrl': i.mediaUrl,
      }).toList(),
      'totalEstimatedTime': totalEstimatedTime.inSeconds,
      'tags': tags,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt,
      'forkInCount': forkInCount,
      'forkOutCount': forkOutCount,
      'forkingoodCount': forkingoodCount,
      'dietaryCriteria': dietaryCriteria,
    };
  }
} 