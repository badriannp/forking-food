import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'user_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserService _userService = UserService();

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

      // Create recipe with only creatorId (no creator data stored)
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
        creatorName: null, // Will be loaded from UserService when needed
        creatorPhotoURL: null, // Will be loaded from UserService when needed
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

      List<Recipe> recipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Recipe.fromMap(data);
      }).toList();

      // Load creator data for all recipes
      return await _loadCreatorDataForRecipes(recipes);
      
    } catch (e) {
      print('Error getting user recipes: $e');
      return [];
    }
  }

  /// Get saved recipes (recipes swiped right by user)
  Future<List<Recipe>> getSavedRecipes(String userId) async {
    try {
      // Get user's swipe data
      DocumentSnapshot swipesDoc = await _firestore
          .collection('swipes')
          .doc(userId)
          .get();

      if (!swipesDoc.exists || swipesDoc.data() == null) {
        return [];
      }

      Map<String, dynamic> swipedRecipes = 
          (swipesDoc.data() as Map<String, dynamic>)['swipedRecipes'] ?? {};

      // Filter recipes that were swiped right (saved)
      List<String> savedRecipeIds = swipedRecipes.entries
          .where((entry) => entry.value == SwipeDirection.right.name)
          .map((entry) => entry.key)
          .toList();

      if (savedRecipeIds.isEmpty) return [];

      // Get the actual recipes in batches (Firestore has a limit of 10 for 'in' queries)
      List<Recipe> recipes = [];
      const int batchSize = 10;
      
      for (int i = 0; i < savedRecipeIds.length; i += batchSize) {
        final batch = savedRecipeIds.skip(i).take(batchSize).toList();
        
        QuerySnapshot recipeSnapshot = await _firestore
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (DocumentSnapshot doc in recipeSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          recipes.add(Recipe.fromMap(data));
        }
      }

      // Sort by creation date (newest first)
      recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Load creator data for all recipes
      return await _loadCreatorDataForRecipes(recipes);
      
    } catch (e) {
      print('Error getting saved recipes: $e');
      return [];
    }
  }

  /// Load creator data for a list of recipes using UserService
  Future<List<Recipe>> _loadCreatorDataForRecipes(List<Recipe> recipes) async {
    try {
      // Get unique creator IDs
      final creatorIds = recipes.map((r) => r.creatorId).toSet().toList();
      print('Loading creator data for ${creatorIds.length} unique creators: $creatorIds');
      
      // Load creator data from UserService
      final creatorData = await _userService.getMultipleUsersData(creatorIds);
      print('Loaded creator data for ${creatorData.length} users');
      
      // Update recipes with creator data
      return recipes.map((recipe) {
        final creator = creatorData[recipe.creatorId];
        if (creator != null) {
          print('Updating recipe ${recipe.id} with creator: ${creator.displayName}');
          return Recipe(
            id: recipe.id,
            title: recipe.title,
            imageUrl: recipe.imageUrl,
            description: recipe.description,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            totalEstimatedTime: recipe.totalEstimatedTime,
            tags: recipe.tags,
            creatorId: recipe.creatorId,
            creatorName: creator.displayName,
            creatorPhotoURL: creator.photoURL,
            createdAt: recipe.createdAt,
            forkInCount: recipe.forkInCount,
            forkOutCount: recipe.forkOutCount,
            forkingoodCount: recipe.forkingoodCount,
            dietaryCriteria: recipe.dietaryCriteria,
          );
        } else {
          print('No creator data found for recipe ${recipe.id} with creatorId: ${recipe.creatorId}');
        }
        return recipe;
      }).toList();
      
    } catch (e) {
      print('Error loading creator data: $e');
      return recipes; // Return original recipes if loading fails
    }
  }

  Future<RecipePaginationResult> getRecipesForFeed({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    List<String>? dietaryCriteria,
    Duration? minTime,
    Duration? maxTime,
  }) async {
    try {
      // 1. Load the IDs of recipes already swiped by the user
      final swipesDoc = await _firestore.collection('swipes').doc(userId).get();
      Set<String> swipedIds = {};
      if (swipesDoc.exists && swipesDoc.data() != null && swipesDoc.data()!['swipedRecipes'] != null) {
        swipedIds = Set<String>.from((swipesDoc.data()!['swipedRecipes'] as Map).keys);
      }

      // 2. Build the query for recipes (exclude own recipes, filters)
      Query query = _firestore.collection('recipes')
          .where('creatorId', isNotEqualTo: userId);

      // Time filters
      if (minTime != null && maxTime != null) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds)
                     .where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      } else if (minTime != null) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds);
      } else if (maxTime != null) {
        query = query.where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      }

      query = query.orderBy('createdAt', descending: true);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      query = query.limit(limit);

      // 3. Execute the query
      QuerySnapshot snapshot = await query.get();

      // 4. Local filter: exclude recipes already swiped and filter by dietary criteria (AND logic)
      List<Recipe> recipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Recipe.fromMap(data);
      })
      .where((r) => !swipedIds.contains(r.id))
      .where((r) => dietaryCriteria == null || dietaryCriteria.isEmpty || dietaryCriteria.every((tag) => r.dietaryCriteria.contains(tag)))
      .toList();

      // Load creator data for all recipes
      recipes = await _loadCreatorDataForRecipes(recipes);

      DocumentSnapshot? newLastDocument = snapshot.docs.isNotEmpty 
          ? snapshot.docs.last 
          : null;

      return RecipePaginationResult(
        recipes: recipes,
        lastDocument: newLastDocument,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      print('Error getting recipes for feed: $e');
      return RecipePaginationResult(
        recipes: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  /// Delete a recipe and all related data (cascade delete)
  Future<void> deleteRecipe(String recipeId, String userId) async {
    try {
      // Verify the user owns this recipe
      DocumentSnapshot recipeDoc = await _firestore
          .collection('recipes')
          .doc(recipeId)
          .get();

      if (!recipeDoc.exists) {
        throw Exception('Recipe not found');
      }

      Map<String, dynamic> recipeData = recipeDoc.data() as Map<String, dynamic>;
      if (recipeData['creatorId'] != userId) {
        throw Exception('You can only delete your own recipes');
      }

      // Delete from all users' swipes (batch operation for efficiency)
      QuerySnapshot swipesSnapshot = await _firestore
          .collection('swipes')
          .get();

      WriteBatch batch = _firestore.batch();
      
      // Remove recipe from all users' swipe data
      for (DocumentSnapshot swipeDoc in swipesSnapshot.docs) {
        Map<String, dynamic> swipeData = swipeDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> swipedRecipes = swipeData['swipedRecipes'] ?? {};
        
        if (swipedRecipes.containsKey(recipeId)) {
          swipedRecipes.remove(recipeId);
          batch.update(swipeDoc.reference, {'swipedRecipes': swipedRecipes});
        }
      }

      // Delete the recipe document
      batch.delete(_firestore.collection('recipes').doc(recipeId));

      // Delete recipe images from Storage
      try {
        // Check if the recipe folder exists before trying to delete
        final recipeFolderRef = _storage.ref('recipes/$recipeId');
        final result = await recipeFolderRef.listAll();
        
        // Delete all files in the recipe folder
        for (Reference item in result.items) {
          try {
            await item.delete();
          } catch (e) {
            print('Warning: Could not delete file ${item.fullPath}: $e');
            // Continue with other files
          }
        }
        
        // Delete subfolders (like instructions)
        for (Reference prefix in result.prefixes) {
          try {
            final subResult = await prefix.listAll();
            for (Reference item in subResult.items) {
              try {
                await item.delete();
              } catch (e) {
                print('Warning: Could not delete file ${item.fullPath}: $e');
              }
            }
          } catch (e) {
            print('Warning: Could not list subfolder ${prefix.fullPath}: $e');
          }
        }
      } catch (e) {
        // If the folder doesn't exist, that's fine - just log it
        if (e.toString().contains('object-not-found')) {
          print('Info: Recipe images folder does not exist, skipping deletion');
        } else {
          print('Warning: Could not delete recipe images: $e');
        }
        // Continue even if image deletion fails
      }

      // Commit all changes
      await batch.commit();

    } catch (e) {
      print('Error deleting recipe: $e');
      throw Exception('Failed to delete recipe: $e');
    }
  }

  /// Get all available tags from the database
  Future<List<String>> getAllTags() async {
    try {
      DocumentSnapshot tagsDoc = await _firestore
          .collection('app_data')
          .doc('tags')
          .get();

      if (tagsDoc.exists && tagsDoc.data() != null) {
        Map<String, dynamic> data = tagsDoc.data() as Map<String, dynamic>;
        List<dynamic> tags = data['tags'] ?? [];
        return tags.cast<String>();
      }
      
      return [];
    } catch (e) {
      print('Error getting tags: $e');
      return [];
    }
  }

  /// Add a new tag to the database
  Future<void> addTag(String tag) async {
    try {
      await _firestore
          .collection('app_data')
          .doc('tags')
          .set({
            'tags': FieldValue.arrayUnion([tag])
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding tag: $e');
      throw Exception('Failed to add tag: $e');
    }
  }

  /// Search tags by query
  Future<List<String>> searchTags(String query) async {
    try {
      List<String> allTags = await getAllTags();
      
      if (query.isEmpty) {
        return allTags;
      }
      
      return allTags
          .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching tags: $e');
      return [];
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