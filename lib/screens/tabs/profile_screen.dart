import 'package:flutter/material.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:flutter/services.dart';
import 'package:forking/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:forking/screens/welcome_screen.dart';
import 'package:forking/services/recipe_service.dart';
import 'package:forking/screens/add_recipe_screen.dart';
import 'package:forking/utils/haptic_feedback.dart';
import 'package:forking/utils/image_utils.dart';
import 'package:forking/widgets/profile_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:forking/widgets/recipes_tab.dart';
import 'package:forking/widgets/creator_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  
  late TabController _tabController;
  List<Recipe> _myRecipes = [];
  List<Recipe> _savedRecipes = [];
  bool _isLoading = true;
  bool _isEditingName = false;
  bool _isUpdatingProfileImage = false;
  bool _showProfileOverlay = false;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Profile image update tracking
  int _profileImageUpdateTimestamp = 0;

  // Filtered recipes based on search with prioritization
  List<Recipe> get _filteredMyRecipes {
    if (_searchQuery.isEmpty) return _myRecipes;
    
    final query = _searchQuery.toLowerCase();
    final scoredRecipes = _myRecipes.map((recipe) {
      int score = 0;
      
      // Title match (highest priority)
      if (recipe.title.toLowerCase().contains(query)) {
        score += 100;
      }
      
      // Description match (medium priority)
      if (recipe.description.toLowerCase().contains(query)) {
        score += 50;
      }
      
      // Ingredients match (medium priority)
      final ingredientMatches = recipe.ingredients
          .where((ingredient) => ingredient.toLowerCase().contains(query))
          .length;
      score += ingredientMatches * 30;
      
      // Tags match (medium priority)
      final tagMatches = recipe.tags
          .where((tag) => tag.toLowerCase().contains(query))
          .length;
      score += tagMatches * 25;
      
      // Dietary criteria match (lower priority)
      final dietaryMatches = recipe.dietaryCriteria
          .where((criteria) => criteria.toLowerCase().contains(query))
          .length;
      score += dietaryMatches * 20;
      
      return _ScoredRecipe(recipe: recipe, score: score);
    }).where((scored) => scored.score > 0).toList();
    
    // Sort by score (descending) and return recipes
    scoredRecipes.sort((a, b) => b.score.compareTo(a.score));
    return scoredRecipes.map((scored) => scored.recipe).toList();
  }

  List<Recipe> get _filteredSavedRecipes {
    if (_searchQuery.isEmpty) return _savedRecipes;
    
    final query = _searchQuery.toLowerCase();
    final scoredRecipes = _savedRecipes.map((recipe) {
      int score = 0;
      
      // Title match (highest priority)
      if (recipe.title.toLowerCase().contains(query)) {
        score += 100;
      }
      
      // Description match (medium priority)
      if (recipe.description.toLowerCase().contains(query)) {
        score += 50;
      }
      
      // Ingredients match (medium priority)
      final ingredientMatches = recipe.ingredients
          .where((ingredient) => ingredient.toLowerCase().contains(query))
          .length;
      score += ingredientMatches * 30;
      
      // Tags match (medium priority)
      final tagMatches = recipe.tags
          .where((tag) => tag.toLowerCase().contains(query))
          .length;
      score += tagMatches * 25;
      
      // Dietary criteria match (lower priority)
      final dietaryMatches = recipe.dietaryCriteria
          .where((criteria) => criteria.toLowerCase().contains(query))
          .length;
      score += dietaryMatches * 20;
      
      return _ScoredRecipe(recipe: recipe, score: score);
    }).where((scored) => scored.score > 0).toList();
    
    // Sort by score (descending) and return recipes
    scoredRecipes.sort((a, b) => b.score.compareTo(a.score));
    return scoredRecipes.map((scored) => scored.recipe).toList();
  }

  // Calculate total fork-ins from all user recipes
  int get _totalForkIns {
    return _myRecipes.fold(0, (sum, recipe) => sum + recipe.forkInCount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize with current user's display name or empty string
    final currentName = _authService.userDisplayName;
    _nameController.text = currentName ?? '';
    
    // Load recipes
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Load user's own recipes
  Future<void> _loadRecipes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final String? userId = _authService.userId;
      
      if (userId != null) {
        // Load both my recipes and saved recipes
        final results = await Future.wait([
          _recipeService.getUserRecipes(userId),
          _recipeService.getSavedRecipes(userId),
        ]);
        
        
        if (mounted) {
          setState(() {
            _myRecipes = results[0];
            _savedRecipes = results[1];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh both recipe lists
  Future<void> _refreshRecipes() async {
    await _loadRecipes();
  }

  Future<void> _pickProfileImage() async {
    if (_isUpdatingProfileImage) return; // Prevent multiple calls
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _isUpdatingProfileImage = true;
        });
      }
      
      try {
        // Crop the image first
        final croppedFile = await _cropProfileImage(File(pickedFile.path));
        
        if (croppedFile == null) {
          // User cancelled cropping
          if (mounted) {
            setState(() {
              _isUpdatingProfileImage = false;
            });
          }
          return;
        }

        // Upload cropped image to Firebase Storage and update profile
        await _authService.updateProfileImage(croppedFile);
        
        // Refresh the UI
        if (mounted) {
          setState(() {
            _isUpdatingProfileImage = false;
            _profileImageUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUpdatingProfileImage = false;
          });
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        }
      }
    }
  }

  /// Crop profile image with user interaction
  Future<File?> _cropProfileImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            cropStyle: CropStyle.circle,
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: false, // Hide grid for cleaner look
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.circle,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
          ),
        ],
      );
      
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      return null;
    }
  }

  /// Show profile photo overlay
  void _showProfilePhotoOverlay() {
    if (_isUpdatingProfileImage) return;
    
    setState(() {
      _showProfileOverlay = true;
    });
    
    // Auto-hide overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showProfileOverlay) {
        setState(() {
          _showProfileOverlay = false;
        });
      }
    });
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isNotEmpty) {
      final newName = _nameController.text.trim();
      final currentName = _authService.userDisplayName ?? '';
      
      // Check if the new name is identical to the current name
      if (newName == currentName) {
        if (mounted) {
        setState(() {
          _isEditingName = false;
        });
        }
        return; // No need to make Firebase call
      }
      
      try {
        await _authService.updateDisplayName(newName);
        
        // User data is now centralized - no need to update recipes
        
        if (mounted) {
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
        }
      } catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update name. Please try again.')),
        );
        }
      }
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog first
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with sign out
    if (shouldSignOut == true) {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
      }
    }
  }

  /// Delete a recipe (only for user's own recipes)
  Future<void> _deleteRecipe(Recipe recipe) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Recipe'),
          content: Text('Are you sure you want to delete "${recipe.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmed) return;

      // Close the recipe modal immediately for better UX
      if (mounted) {
        Navigator.of(context).pop(); // Close recipe modal
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Deleting recipe...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final String? userId = _authService.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _recipeService.deleteRecipe(recipe.id, userId);

      // Refresh recipes
      await _loadRecipes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap outside to save name if editing
        if (_isEditingName) {
          _saveName();
        }
        // Unfocus any active text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          elevation: 0,
          title: Text(
            'Forking',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'EduNSWACTHand',
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 28,
            ),
          ),
        leading: null,
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                await HapticUtils.triggerHeavyImpact();
                _signOut();
              },
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) {
              return [
                SliverToBoxAdapter(child: _buildProfileHeader(context)),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      indicatorAnimation: TabIndicatorAnimation.elastic,
                      dividerHeight: 0.125,
                      dividerColor: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                      isScrollable: false,
                    controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    splashFactory: NoSplash.splashFactory,
                      tabs: const [
                        Tab(text: 'My Recipes'),
                        Tab(text: 'Saved'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
            controller: _tabController,
            children: [
              RecipeTabView(
                onRefresh: _refreshRecipes,
                searchBarBuilder: _buildSearchBar,
                gridBuilder: () => _buildRecipesGrid(isSaved: false),
              ),
              RecipeTabView(
                onRefresh: _refreshRecipes,
                searchBarBuilder: _buildSearchBar,
                gridBuilder: () => _buildRecipesGrid(isSaved: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final userDisplayName = _authService.userDisplayName ?? 'User';
    final userPhotoURL = _authService.userPhotoURL;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo with edit button
          Stack(
            children: [
              // Profile photo with tap detection
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _showProfilePhotoOverlay,
                child: ProfileAvatarImage(
                  key: ValueKey('profile_$_profileImageUpdateTimestamp'),
                  imageUrl: userPhotoURL, 
                  radius: 44
                ),
              ),
              // Loading overlay
              if (_isUpdatingProfileImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              // Edit overlay (appears on tap)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _showProfileOverlay && !_isUpdatingProfileImage ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: !_showProfileOverlay || _isUpdatingProfileImage,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                        child: const Center(
                    child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name with edit functionality
                if (_isEditingName) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 2),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(width: 1, color: Colors.grey),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(width: 1, color: Colors.grey),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary),
                            ),
                            hintText: 'Enter your name',
                            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                          onSubmitted: (_) => _saveName(),
                          onEditingComplete: _saveName,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: _saveName,
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Save',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = userDisplayName;
                          });
                        },
                        color: Theme.of(context).colorScheme.error,
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userDisplayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isEditingName = true;
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _nameFocus.requestFocus();
                          });
                        },
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Edit name',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatFlex(context, Icons.kitchen, _myRecipes.length.toString(), 'Recipes'),
                    _buildStatFlex(context, Icons.restaurant, _totalForkIns.toString(), 'Fork-ins'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 8),
      height: 32,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          hintText: 'Search',
        ),
      ),
    );
  }

  Widget _buildStatFlex(BuildContext context, IconData icon, String value, String label) {
    final color = Theme.of(context).colorScheme.onSurface.withAlpha(200);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withAlpha(150),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid({bool isSaved = false}) {
    final recipes = isSaved ? _filteredSavedRecipes : _filteredMyRecipes;
    final isLoading = _isLoading;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (recipes.isEmpty && !isLoading && isSaved) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fork-in recipes to save them\nin your collection!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: isSaved ? recipes.length : recipes.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        // Show add button as first item for My Recipes
        if (!isSaved && index == 0) {
          return _buildAddRecipeCard();
        }
        
        // Adjust index for recipes (skip add button)
        final recipeIndex = isSaved ? index : index - 1;
        final recipe = recipes[recipeIndex];
        
        return GestureDetector(
          onTap: () {
            _showRecipeCardOverlay(context, recipe);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  fadeInDuration: Duration.zero,
                  imageUrl: getResizedImageUrl(originalUrl: recipe.imageUrl, size: 600),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      imageUrl: recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
                // Gradient peste imagine pentru text
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(179),
                      ],
                    ),
                  ),
                ),
                // Fork-in count in top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.forkInCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Time in top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(recipe.totalEstimatedTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Title and chef name in left bottom
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSaved) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Chef avatar
                            CreatorAvatar(
                              imageUrl: recipe.creatorPhotoURL,
                              size: 16,
                              borderColor: Colors.white,
                              fallbackColor: Colors.white.withAlpha(75),
                            ),
                            const SizedBox(width: 4),
                            // Chef name
                            Expanded(
                              child: Text(
                                recipe.creatorName ?? 'Unknown Chef',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddRecipeCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddRecipeScreen(
              onRecipeAdded: () {
                _loadRecipes();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.grey[50],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Recipe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format time duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  void _showRecipeCardOverlay(BuildContext context, Recipe recipe) {
    final bool isOwnRecipe = recipe.creatorId == _authService.userId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
          backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SafeArea(
        top: true,
        bottom: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Stack(
            children: [
              // RecipeCard
              LayoutBuilder(
                builder: (context, constraints) {
                  return RecipeCard(
                    recipe: recipe,
                    constraints: constraints,
                  );
                },
              ),
              // Drag indicator at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 65,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Delete button (only for own recipes)
              if (isOwnRecipe) ...[
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () async {
                      await HapticUtils.triggerHeavyImpact();
                      _deleteRecipe(recipe);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              ],
            ],
          ),
        ),
          ),
    );
  }
}

class _ScoredRecipe {
  final Recipe recipe;
  final int score;
  
  _ScoredRecipe({required this.recipe, required this.score});
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 