import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get recipes for swiping with cursor pagination
  Future<RecipePaginationResult> getRecipesForSwipe({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    List<String>? dietaryCriteria,
    Duration? minTime,
    Duration? maxTime,
  }) async {
    try {
      // Build the base query
      Query query = _firestore.collection('recipes')
          .where('creatorId', isNotEqualTo: userId); // Exclude own recipes

      // Add dietary criteria filter if provided
      if (dietaryCriteria != null && dietaryCriteria.isNotEmpty) {
        // For now, we'll filter client-side for multiple criteria
        // In production, you might want to use array-contains-any or similar
      }

      // Add time filter if provided
      if (minTime != null && maxTime != null) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds)
                     .where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      } else if (minTime != null) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds);
      } else if (maxTime != null) {
        query = query.where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      }

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      // Add cursor pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Limit results
      query = query.limit(limit);

      // Execute query
      QuerySnapshot snapshot = await query.get();

      // Convert to Recipe objects
      List<Recipe> recipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return Recipe.fromMap(data);
      }).toList();

      // Get the last document for next pagination
      DocumentSnapshot? newLastDocument = snapshot.docs.isNotEmpty 
          ? snapshot.docs.last 
          : null;

      return RecipePaginationResult(
        recipes: recipes,
        lastDocument: newLastDocument,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      print('Error getting recipes: $e');
      return RecipePaginationResult(
        recipes: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  /// Save a new recipe to Firestore
  Future<String> saveRecipe(Recipe recipe) async {
    try {
      // Upload main image if it's a local file
      String imageUrl = recipe.imageUrl;
      if (recipe.imageUrl.startsWith('file://') || recipe.imageUrl.startsWith('/')) {
        imageUrl = await _uploadImage(recipe.imageUrl, 'recipes/${recipe.id}/main');
      }

      // Upload instruction images
      List<InstructionStep> updatedInstructions = [];
      for (int i = 0; i < recipe.instructions.length; i++) {
        InstructionStep step = recipe.instructions[i];
        String? mediaUrl = step.mediaUrl;
        
        if (step.localMediaFile != null) {
          mediaUrl = await _uploadImage(
            step.localMediaFile!.path, 
            'recipes/${recipe.id}/instructions/$i'
          );
        }
        
        updatedInstructions.add(InstructionStep(
          description: step.description,
          mediaUrl: mediaUrl,
        ));
      }

      // Create recipe with updated URLs
      Recipe updatedRecipe = Recipe(
        id: recipe.id,
        title: recipe.title,
        imageUrl: imageUrl,
        description: recipe.description,
        ingredients: recipe.ingredients,
        instructions: updatedInstructions,
        totalEstimatedTime: recipe.totalEstimatedTime,
        tags: recipe.tags,
        creatorId: recipe.creatorId,
        creatorName: recipe.creatorName,
        createdAt: recipe.createdAt,
        dietaryCriteria: recipe.dietaryCriteria,
      );

      // Save to Firestore
      await _firestore
          .collection('recipes')
          .doc(recipe.id)
          .set(updatedRecipe.toMap());

      return recipe.id;
    } catch (e) {
      print('Error saving recipe: $e');
      throw Exception('Failed to save recipe: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(String imagePath, String storagePath) async {
    try {
      File imageFile = File(imagePath);
      // Citește și decodează imaginea
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Could not decode image');
      }
      // Redimensionează la max 1200px pe latura mare (opțional, pentru optimizare)
      final resized = img.copyResize(image, width: 1200, interpolation: img.Interpolation.linear);
      // Encodează ca JPEG cu 85% calitate
      final jpegBytes = img.encodeJpg(resized, quality: 85);
      Reference ref = _storage.ref().child('$storagePath.jpg');
      UploadTask uploadTask = ref.putData(Uint8List.fromList(jpegBytes));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Save a swipe action
  Future<void> saveSwipe({
    required String userId,
    required String recipeId,
    required SwipeDirection direction,
  }) async {
    try {
      await _firestore
          .collection('swipes')
          .doc(userId)
          .set({
            'swipedRecipes': {
              recipeId: direction.name,
            }
          }, SetOptions(merge: true));

      // Increment/decrement forkInCount on recipe
      final recipeRef = _firestore.collection('recipes').doc(recipeId);
      if (direction == SwipeDirection.right) {
        await recipeRef.update({'forkInCount': FieldValue.increment(1)});
      } else if (direction == SwipeDirection.left) {
        await recipeRef.update({'forkOutCount': FieldValue.increment(1)});
      }
    } catch (e) {
      print('Error saving swipe: $e');
    }
  }

  /// Get user's own recipes
  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting user recipes: $e');
      return [];
    }
  }

  /// Get saved recipes
  Future<List<Recipe>> getSavedRecipes(String userId) async {
    try {
      // Get user's saved recipe IDs
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      List<String> savedRecipeIds = List<String>.from(
        (userDoc.data() as Map<String, dynamic>?)?['savedRecipes'] ?? []
      );

      if (savedRecipeIds.isEmpty) return [];

      // Get the actual recipes
      List<Recipe> recipes = [];
      for (String recipeId in savedRecipeIds) {
        DocumentSnapshot recipeDoc = await _firestore
            .collection('recipes')
            .doc(recipeId)
            .get();

        if (recipeDoc.exists) {
          Map<String, dynamic> data = recipeDoc.data() as Map<String, dynamic>;
          data['id'] = recipeDoc.id;
          recipes.add(Recipe.fromMap(data));
        }
      }

      return recipes;
    } catch (e) {
      print('Error getting saved recipes: $e');
      return [];
    }
  }

  /// Update all recipes when user changes profile data
  Future<void> updateUserRecipesData({
    required String userId,
    required String newDisplayName,
    required String? newPhotoURL,
  }) async {
    try {
      // Get all recipes by this user
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('creatorId', isEqualTo: userId)
          .get();

      // Update each recipe in a batch
      WriteBatch batch = _firestore.batch();
      
      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> updates = {
          'creatorName': newDisplayName,
        };
        
        if (newPhotoURL != null) {
          updates['creatorPhotoURL'] = newPhotoURL;
        }
        
        batch.update(doc.reference, updates);
      }

      // Commit the batch
      await batch.commit();
      
      print('Updated ${snapshot.docs.length} recipes for user $userId');
    } catch (e) {
      print('Error updating user recipes: $e');
      throw Exception('Failed to update user recipes: $e');
    }
  }
}

/// Result class for pagination
class RecipePaginationResult {
  final List<Recipe> recipes;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  RecipePaginationResult({
    required this.recipes,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Swipe direction enum
enum SwipeDirection {
  left,   // Dislike/Skip
  right,  // Like/Fork
} 