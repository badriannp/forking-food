import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'user_service.dart';
import 'package:forking/utils/image_utils.dart' as image_utils;

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
      // Resize to max 1200px on the larger side (optional, for optimization)
      final resized = img.copyResize(image, width: 1200, interpolation: img.Interpolation.linear);
      // Encode as JPEG with 85% quality
      final jpegBytes = img.encodeJpg(resized, quality: 85);
      Reference ref = _storage.ref().child('$storagePath.jpg');
      final metadata = SettableMetadata(contentType: image_utils.getContentTypeFromPath(imagePath));
      UploadTask uploadTask = ref.putData(Uint8List.fromList(jpegBytes), metadata);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> saveSwipe({
    required String userId,
    required String recipeId,
    required SwipeDirection direction,
  }) async {
    try {
      // Save to user's swipe history
      await _firestore
          .collection('swipes')
          .doc(userId)
          .set({
            'swipedRecipes': {
              recipeId: direction.name,
            }
          }, SetOptions(merge: true));

      // Track daily likes if it's a right swipe (like)
      if (direction == SwipeDirection.right) {
        await _incrementDailyLike(recipeId);
        // Update user preference scores when they like a recipe
        await _updateUserPreferenceScores(userId, recipeId, true);
      } else if (direction == SwipeDirection.left) {
        // Update user preference scores when they dislike a recipe
        await _updateUserPreferenceScores(userId, recipeId, false);
      }

      // Increment/decrement forkInCount on recipe (overall count)
      final recipeRef = _firestore.collection('recipes').doc(recipeId);
      if (direction == SwipeDirection.right) {
        await recipeRef.update({'forkInCount': FieldValue.increment(1)});
      } else if (direction == SwipeDirection.left) {
        await recipeRef.update({'forkOutCount': FieldValue.increment(1)});
      }
    } catch (e) {
      // Error saving swipe
    }
  }

  /// Update user preference scores based on their swipe
  Future<void> _updateUserPreferenceScores(String userId, String recipeId, bool isLike) async {
    try {
      // Get the recipe to analyze its characteristics
      DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
      if (!recipeDoc.exists) return;
      
      Map<String, dynamic> recipeData = recipeDoc.data() as Map<String, dynamic>;
      Recipe recipe = Recipe.fromMap({...recipeData, 'id': recipeId});
      
      // Get current user preferences
      DocumentSnapshot userPrefsDoc = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();
      
      Map<String, dynamic> currentPrefs = {};
      if (userPrefsDoc.exists && userPrefsDoc.data() != null) {
        currentPrefs = Map<String, dynamic>.from(userPrefsDoc.data() as Map<String, dynamic>);
      }
      
      // Update ingredient scores
      Map<String, double> ingredientScores = Map<String, double>.from(
        currentPrefs['ingredientScores'] ?? {}
      );
      
      for (String ingredient in recipe.ingredients) {
        final key = ingredient.toLowerCase();
        ingredientScores[key] = (ingredientScores[key] ?? 0) + (isLike ? 1 : -0.5);
        // Ensure score doesn't go below 0
        if (ingredientScores[key]! < 0) ingredientScores[key] = 0;
      }
      
      // Update dietary criteria scores
      Map<String, double> dietaryScores = Map<String, double>.from(
        currentPrefs['dietaryScores'] ?? {}
      );
      
      for (String criteria in recipe.dietaryCriteria) {
        final key = criteria.toLowerCase();
        dietaryScores[key] = (dietaryScores[key] ?? 0) + (isLike ? 1 : -0.5);
        if (dietaryScores[key]! < 0) dietaryScores[key] = 0;
      }
      
      // Update tag scores
      Map<String, double> tagScores = Map<String, double>.from(
        currentPrefs['tagScores'] ?? {}
      );
      
      for (String tag in recipe.tags) {
        final key = tag.toLowerCase();
        tagScores[key] = (tagScores[key] ?? 0) + (isLike ? 1 : -0.5);
        if (tagScores[key]! < 0) tagScores[key] = 0;
      }
      
      // Save updated preferences
      await _firestore
          .collection('user_preferences')
          .doc(userId)
          .set({
            'userId': userId,
            'ingredientScores': ingredientScores,
            'dietaryScores': dietaryScores,
            'tagScores': tagScores,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
    } catch (e) {
      // Error updating user preference scores
    }
  }

  /// Increment daily like count for a recipe
  Future<void> _incrementDailyLike(String recipeId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      await _firestore
          .collection('daily_likes')
          .doc(today)
          .set({
            'date': today,
            'likes': {
              recipeId: FieldValue.increment(1),
            }
          }, SetOptions(merge: true));
    } catch (e) {
      // Error incrementing daily like
    }
  }

  /// Get today's leaderboard (top 3 most liked recipes today)
  Future<List<Recipe>> getTodayLeaderboard({int limit = 3}) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get today's likes document
      DocumentSnapshot dailyLikesDoc = await _firestore
          .collection('daily_likes')
          .doc(today)
          .get();
      
      List<Recipe> recipes = [];
      
      if (dailyLikesDoc.exists && dailyLikesDoc.data() != null) {
        Map<String, dynamic> data = dailyLikesDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> likes = data['likes'] ?? {};
        
        if (likes.isNotEmpty) {
          // Sort recipes by today's like count
          List<MapEntry<String, dynamic>> sortedLikes = likes.entries.toList()
            ..sort((a, b) => (b.value as int).compareTo(a.value as int));
          
          // Get top recipes
          final topRecipeIds = sortedLikes
              .take(limit)
              .map((entry) => entry.key)
              .toList();
          
          // Get the actual recipe documents
          recipes = await _getRecipesByIds(topRecipeIds);
          
          // Update recipes with today's fork-ins count and maintain correct order
          Map<String, Recipe> recipeMap = {};
          for (Recipe recipe in recipes) {
            recipeMap[recipe.id] = recipe;
          }
          
          // Rebuild recipes list in the correct order
          recipes = topRecipeIds.map((recipeId) {
            final recipe = recipeMap[recipeId];
            if (recipe != null) {
              final todayLikes = likes[recipeId] as int? ?? 0;
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
                creatorName: recipe.creatorName,
                creatorPhotoURL: recipe.creatorPhotoURL,
                createdAt: recipe.createdAt,
                forkInCount: todayLikes, // Use today's likes instead of total
                forkOutCount: recipe.forkOutCount,
                forkingoodCount: recipe.forkingoodCount,
                dietaryCriteria: recipe.dietaryCriteria,
              );
            }
            return recipe!;
          }).toList();
        }
      }
      
      // Load creator data for all recipes
      recipes = await _loadCreatorDataForRecipes(recipes);
      await cleanupOldDailyLikes();
      return recipes;
    } catch (e) {
      // Error getting today leaderboard
      return [];
    }
  }

  /// Clean up old daily likes
  Future<void> cleanupOldDailyLikes() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get all daily likes documents
      QuerySnapshot snapshot = await _firestore
          .collection('daily_likes')
          .get();
      
      // Delete all documents except today's
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        if (doc.id != today) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
    } catch (e) {
      // Error cleaning up old daily likes
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
      // Error getting user recipes
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
      // Error getting saved recipes
      return [];
    }
  }

  /// Load creator data for a list of recipes using UserService
  Future<List<Recipe>> _loadCreatorDataForRecipes(List<Recipe> recipes) async {
    try {
      // Get unique creator IDs
      final creatorIds = recipes.map((r) => r.creatorId).toSet().toList();
      
      // Load creator data from UserService
      final creatorData = await _userService.getMultipleUsersData(creatorIds);
      
      // Update recipes with creator data
      return recipes.map((recipe) {
        final creator = creatorData[recipe.creatorId];
        if (creator != null) {
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
          // No creator data found for recipe
        }
        return recipe;
      }).toList();
      
    } catch (e) {
      // Error loading creator data
      return recipes; // Return original recipes if loading fails
    }
  }

  /// Get recipes for feed (original method - delegates to precise implementation)
  Future<RecipePaginationResult> getRecipesForFeed({
    required String userId,
    DocumentSnapshot? lastDocument,
    DateTime? lastTimestamp,
    int limit = 3,
    List<String>? dietaryCriteria,
    Duration? minTime,
    Duration? maxTime,
  }) async {
    return getRecipesForFeedPrecise(
      userId: userId,
      lastDocument: lastDocument,
      lastTimestamp: lastTimestamp,
      limit: limit,
      dietaryCriteria: dietaryCriteria,
      minTime: minTime,
      maxTime: maxTime,
    );
  }

  /// Get recipes for feed with optimized queries and proper indexing
  Future<RecipePaginationResult> getRecipesForFeedPrecise({
    required String userId,
    DocumentSnapshot? lastDocument,
    DateTime? lastTimestamp,
    int limit = 3,
    List<String>? dietaryCriteria,
    Duration? minTime,
    Duration? maxTime,
  }) async {
    try {
      // 1. Get user's swiped recipes (cached for efficiency)
      final swipesDoc = await _firestore.collection('swipes').doc(userId).get();
      Set<String> swipedIds = {};
      if (swipesDoc.exists && swipesDoc.data() != null && swipesDoc.data()!['swipedRecipes'] != null) {
        swipedIds = Set<String>.from((swipesDoc.data()!['swipedRecipes'] as Map).keys);
      }

      // 2. Build optimized query based on available filters
      Query query = _firestore.collection('recipes')
          .where('creatorId', isNotEqualTo: userId);

      // Apply time filters if specified
      if (minTime != null && maxTime != null && minTime.inMinutes != -1 && maxTime.inMinutes != -1) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds)
                     .where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      } else if (minTime != null && minTime.inMinutes != -1) {
        query = query.where('totalEstimatedTime', isGreaterThanOrEqualTo: minTime.inSeconds);
      } else if (maxTime != null && maxTime.inMinutes != -1) {
        query = query.where('totalEstimatedTime', isLessThanOrEqualTo: maxTime.inSeconds);
      }

      // Apply dietary criteria filter if specified
      if (dietaryCriteria != null && dietaryCriteria.isNotEmpty) {
        // Use array-contains-any for better performance
        query = query.where('dietaryCriteria', arrayContainsAny: dietaryCriteria);
      }

      // Order by creation date for consistent pagination
      query = query.orderBy('createdAt', descending: true);

      // 3. Handle pagination using timestamp (more reliable than document)
      if (lastTimestamp != null) {
        query = query.where('createdAt', isLessThan: lastTimestamp);
      } else if (lastDocument != null) {
        // Fallback to document-based pagination for backward compatibility
        query = query.startAfterDocument(lastDocument);
      }

      // 4. Fetch with larger batch size to account for filtering
      int batchSize = limit * 3; // Increased batch size for better filtering
      QuerySnapshot snapshot = await query.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        return RecipePaginationResult(
          recipes: [],
          lastDocument: null,
          lastTimestamp: null,
          hasMore: false,
        );
      }

      // 5. Convert to recipes and apply remaining filters
      List<Recipe> allRecipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Recipe.fromMap(data);
      }).toList();

      // Apply local filters that can't be done in Firebase
      List<Recipe> filteredRecipes = allRecipes
          .where((r) => !swipedIds.contains(r.id)) // Exclude swiped recipes
          .where((r) {
            // Additional dietary criteria filtering (for exact matches)
            if (dietaryCriteria == null || dietaryCriteria.isEmpty) return true;
            return dietaryCriteria.every((criteria) => r.dietaryCriteria.contains(criteria));
          })
          .toList();

      // 6. If all recipes are swiped, try to load more automatically
      if (filteredRecipes.isEmpty && snapshot.docs.length >= batchSize) {
        // Get the last timestamp from the current batch
        DateTime? nextTimestamp = allRecipes.isNotEmpty ? allRecipes.last.createdAt : null;
        
        if (nextTimestamp != null) {
          // Recursively call with the next timestamp
          return getRecipesForFeedPrecise(
            userId: userId,
            lastTimestamp: nextTimestamp,
            limit: limit,
            dietaryCriteria: dietaryCriteria,
            minTime: minTime,
            maxTime: maxTime,
          );
        }
      }

      // 7. Return all valid recipes (not just the limit)
      // This allows the HomeScreen to manage the pool properly
      List<Recipe> finalRecipes = filteredRecipes.toList(); // Return all valid recipes

      // 8. Determine if there are more recipes available
      bool hasMore = snapshot.docs.length >= batchSize; // If we got a full batch, there might be more

      // 9. Set the last timestamp for pagination (more reliable than document)
      DateTime? lastTime = finalRecipes.isNotEmpty ? finalRecipes.last.createdAt : null;
      
      // Keep lastDocument for backward compatibility
      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      // 10. Load creator data efficiently
      if (finalRecipes.isNotEmpty) {
        finalRecipes = await _loadCreatorDataForRecipes(finalRecipes);
      }

      return RecipePaginationResult(
        recipes: finalRecipes,
        lastDocument: lastDoc,
        lastTimestamp: lastTime,
        hasMore: hasMore,
      );
    } catch (e) {
      return RecipePaginationResult(
        recipes: [],
        lastDocument: null,
        lastTimestamp: null,
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
                // Could not delete file
              }
            }
          } catch (e) {
            // Could not list subfolder
          }
        }
      } catch (e) {
        // If the folder doesn't exist, that's fine - just log it
        if (e.toString().contains('object-not-found')) {
          // Recipe images folder does not exist, skipping deletion
        } else {
          // Could not delete recipe images
        }
        // Continue even if image deletion fails
      }

      // Commit all changes
      await batch.commit();

    } catch (e) {
      // Error deleting recipe
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
      // Error getting tags
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
      // Error adding tag
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
      // Error searching tags
      return [];
    }
  }

  /// Get personalized recommendations based on user preferences
  Future<List<Recipe>> getPersonalizedRecommendations({
    required String userId,
    int limit = 8,
  }) async {
    try {
      // Get user's swipe history to exclude already swiped recipes
      final swipesDoc = await _firestore.collection('swipes').doc(userId).get();
      Map<String, String> swipedRecipes = {};
      
      if (swipesDoc.exists && swipesDoc.data() != null) {
        swipedRecipes = Map<String, String>.from(
          (swipesDoc.data() as Map<String, dynamic>)['swipedRecipes'] ?? {}
        );
      }
      
      // Get all recipes that are not user's own recipes
      QuerySnapshot snapshot = await _firestore.collection('recipes')
          .where('creatorId', isNotEqualTo: userId) // Exclude own recipes
          .get();
      
      List<Recipe> allRecipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Recipe.fromMap(data);
      }).toList();
      
      // Filter out already swiped recipes
      allRecipes = allRecipes.where((recipe) => 
        !swipedRecipes.containsKey(recipe.id)
      ).toList();
      
      if (allRecipes.isEmpty) {
        return [];
      }
      
      // Get user's saved preference scores
      DocumentSnapshot userPrefsDoc = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();
      
      Map<String, double> ingredientScores = {};
      Map<String, double> dietaryScores = {};
      Map<String, double> tagScores = {};
      
      if (userPrefsDoc.exists && userPrefsDoc.data() != null) {
        Map<String, dynamic> prefsData = userPrefsDoc.data() as Map<String, dynamic>;
        ingredientScores = Map<String, double>.from(prefsData['ingredientScores'] ?? {});
        dietaryScores = Map<String, double>.from(prefsData['dietaryScores'] ?? {});
        tagScores = Map<String, double>.from(prefsData['tagScores'] ?? {});
      }
      
      // Score all available recipes using saved preferences
      List<_ScoredRecipe> scoredRecipes = allRecipes.map((recipe) {
        double totalScore = 0;
        
        // Ingredient score (35%)
        double ingredientScore = 0;
        for (final ingredient in recipe.ingredients) {
          ingredientScore += ingredientScores[ingredient.toLowerCase()] ?? 0;
        }
        if (recipe.ingredients.isNotEmpty) {
          totalScore += (ingredientScore / recipe.ingredients.length) * 0.35;
        }
        
        // Dietary criteria score (30%)
        double dietaryScore = 0;
        for (final criteria in recipe.dietaryCriteria) {
          dietaryScore += dietaryScores[criteria.toLowerCase()] ?? 0;
        }
        if (recipe.dietaryCriteria.isNotEmpty) {
          totalScore += (dietaryScore / recipe.dietaryCriteria.length) * 0.30;
        }
        
        // Tag score (20%)
        double tagScore = 0;
        for (final tag in recipe.tags) {
          tagScore += tagScores[tag.toLowerCase()] ?? 0;
        }
        if (recipe.tags.isNotEmpty) {
          totalScore += (tagScore / recipe.tags.length) * 0.20;
        }
        
        // Photos number score (15%) - more photos = better
        double photoScore = recipe.instructions
            .where((step) => step.mediaUrl != null)
            .length / recipe.instructions.length;
        totalScore += photoScore * 0.15;
        
        // Add some randomness to avoid always showing the same recipes
        totalScore += (DateTime.now().millisecondsSinceEpoch % 100) / 1000;
        
        return _ScoredRecipe(recipe: recipe, score: totalScore);
      }).toList();
      
      // Sort by score (descending) and take top recipes
      scoredRecipes.sort((a, b) => b.score.compareTo(a.score));
      final topRecipes = scoredRecipes
          .take(limit)
          .map((scored) => scored.recipe)
          .toList();
      
      // Load creator data for all recipes
      return await _loadCreatorDataForRecipes(topRecipes);
      
    } catch (e) {
      // Error getting personalized recommendations
      // Fallback to empty list if recommendation algorithm fails
      return [];
    }
  }
  
  /// Get recipes by IDs
  Future<List<Recipe>> _getRecipesByIds(List<String> recipeIds) async {
    try {
      List<Recipe> recipes = [];
      const int batchSize = 10; // Firestore limit for 'in' queries
      
      for (int i = 0; i < recipeIds.length; i += batchSize) {
        final batch = recipeIds.skip(i).take(batchSize).toList();
        
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (DocumentSnapshot doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          recipes.add(Recipe.fromMap(data));
        }
      }
      
      return recipes;
    } catch (e) {
      // Error getting recipes by IDs
      return [];
    }
  }

  /// Get all dietary criteria from database
  Future<List<String>> getAllDietaryCriteria() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('dietary_criteria')
          .orderBy('name')
          .get();
      
      // If no dietary criteria exist, populate with defaults
      if (querySnapshot.docs.isEmpty) {
        await _populateDefaultDietaryCriteria();
        // Fetch again after populating
        querySnapshot = await _firestore
            .collection('dietary_criteria')
            .orderBy('name')
            .get();
      }
      
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['name'] as String)
          .toList();
    } catch (e) {
      // Error loading dietary criteria
      // Return default list if database fails
      return [
        'Vegan',
        'Vegetarian',
        'Lactose Free',
        'Gluten Free',
        'Nut Free',
        'Dairy Free',
        'Egg Free',
        'Sugar Free',
        'Low Carb',
        'Low Fat',
        'Paleo',
        'Keto',
        'Halal',
        'Kosher',
      ];
    }
  }

  /// Populate database with default dietary criteria
  Future<void> _populateDefaultDietaryCriteria() async {
    final defaultCriteria = [
      'Vegan',
      'Vegetarian', 
      'Lactose Free',
      'Gluten Free',
      'Nut Free',
      'Dairy Free',
      'Egg Free',
      'Sugar Free',
      'Low Carb',
      'Low Fat',
      'Paleo',
      'Keto',
      'Halal',
      'Kosher',
    ];
    
    for (String criteria in defaultCriteria) {
      try {
        await _firestore
            .collection('dietary_criteria')
            .doc(criteria.toLowerCase().replaceAll(' ', '_'))
            .set({
              'name': criteria,
              'createdAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        // Error adding default dietary criteria
      }
    }
  }

  /// Add a new dietary criteria to database
  Future<void> addDietaryCriteria(String criteria) async {
    try {
      final cleanCriteria = _normalizeDietaryCriteria(criteria.trim());
      if (cleanCriteria.isEmpty) return;
      
      await _firestore
          .collection('dietary_criteria')
          .doc(cleanCriteria.toLowerCase().replaceAll(' ', '_'))
          .set({
            'name': cleanCriteria,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Error adding dietary criteria
      throw Exception('Failed to add dietary criteria: $e');
    }
  }

  /// Normalize dietary criteria to Title Case
  String _normalizeDietaryCriteria(String criteria) {
    if (criteria.isEmpty) return criteria;
    
    // Convert to Title Case (first letter of each word uppercase)
    return criteria.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Search dietary criteria based on query
  Future<List<String>> searchDietaryCriteria(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllDietaryCriteria();
      }
      
      // Normalize query to Title Case for case-insensitive search
      final normalizedQuery = _normalizeDietaryCriteria(query);
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('dietary_criteria')
          .where('name', isGreaterThanOrEqualTo: normalizedQuery)
          .where('name', isLessThan: '$normalizedQuery\uf8ff')
          .orderBy('name')
          .limit(10)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['name'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Result class for pagination
class RecipePaginationResult {
  final List<Recipe> recipes;
  final DocumentSnapshot? lastDocument;
  final DateTime? lastTimestamp;
  final bool hasMore;

  RecipePaginationResult({
    required this.recipes,
    this.lastDocument,
    this.lastTimestamp,
    required this.hasMore,
  });
}

/// Swipe direction enum
enum SwipeDirection {
  left,   // Dislike/Skip
  right,  // Like/Fork
}

class _ScoredRecipe {
  final Recipe recipe;
  final double score;
  
  _ScoredRecipe({required this.recipe, required this.score});
} 