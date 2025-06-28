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
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

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
    super.dispose();
  }

  /// Load user's own recipes
  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? userId = _authService.userId;
      print('Loading recipes for userId: $userId');
      
      if (userId != null) {
        // Load both my recipes and saved recipes
        final results = await Future.wait([
          _recipeService.getUserRecipes(userId),
          _recipeService.getSavedRecipes(userId),
        ]);
        
        print('Loaded ${results[0].length} my recipes and ${results[1].length} saved recipes');
        
        setState(() {
          _myRecipes = results[0];
          _savedRecipes = results[1];
          _isLoading = false;
        });
      } else {
        print('UserId is null - user not authenticated');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });
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
      imageQuality: 100, // Keep original quality for cropping
    );

    if (pickedFile != null) {
      setState(() {
        _isUpdatingProfileImage = true;
      });
      
      try {
        // Crop the image first
        final croppedFile = await _cropProfileImage(File(pickedFile.path));
        
        if (croppedFile == null) {
          // User cancelled cropping
          setState(() {
            _isUpdatingProfileImage = false;
          });
          return;
        }

        // Upload cropped image to Firebase Storage and update profile
        await _authService.updateProfileImage(croppedFile);
        
        final String? userId = _authService.userId;
        if (userId != null) {
          // User data is now centralized - no need to update recipes
          print('Profile photo updated - user data centralized');
        }
        
        // Refresh the UI
        setState(() {
          _isUpdatingProfileImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
      } catch (e) {
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
      print('Error cropping profile image: $e');
      return null;
    }
  }


  Future<void> _saveName() async {
    if (_nameController.text.trim().isNotEmpty) {
      final newName = _nameController.text.trim();
      final currentName = _authService.userDisplayName ?? '';
      
      // Check if the new name is identical to the current name
      if (newName == currentName) {
        setState(() {
          _isEditingName = false;
        });
        return; // No need to make Firebase call
      }
      
      try {
        await _authService.updateDisplayName(newName);
        
        // User data is now centralized - no need to update recipes
        print('Display name updated - user data centralized');
        
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update name. Please try again.')),
        );
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
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
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
    return Scaffold(
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _signOut,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: _buildProfileHeader(context)),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  indicatorColor: Theme.of(context).colorScheme.primary,
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
            // Grid for "My Recipes" with pull-to-refresh
            RefreshIndicator(
              onRefresh: _refreshRecipes,
              child: _buildRecipesGrid(),
            ),
            // Grid for "Saved" recipes with pull-to-refresh
            RefreshIndicator(
              onRefresh: _refreshRecipes,
              child: _buildRecipesGrid(isSaved: true),
            ),
          ],
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
              CircleAvatar(
                radius: 44,
                backgroundImage: userPhotoURL != null 
                    ? NetworkImage(userPhotoURL)
                    : null,
                child: userPhotoURL == null 
                    ? Icon(
                        Icons.person,
                        size: 44,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      )
                    : null,
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
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUpdatingProfileImage ? null : _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isUpdatingProfileImage 
                          ? Theme.of(context).colorScheme.onSurface.withAlpha(100)
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isUpdatingProfileImage ? Icons.hourglass_empty : Icons.camera_alt,
                      size: 16,
                      color: _isUpdatingProfileImage 
                          ? Theme.of(context).colorScheme.onSurface.withAlpha(150)
                          : Theme.of(context).colorScheme.onPrimary,
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
                            fontSize: 19,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveName,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = userDisplayName;
                          });
                        },
                        color: Theme.of(context).colorScheme.error,
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
                        onPressed: () {
                          setState(() {
                            _isEditingName = true;
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _nameFocus.requestFocus();
                          });
                        },
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatFlex(context, Icons.kitchen, _myRecipes.length.toString(), 'Recipes'),
                    _buildStatFlex(context, Icons.fork_left, _totalForkIns.toString(), 'Fork-ins'),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final recipes = isSaved ? _savedRecipes : _myRecipes;
    final isLoading = _isLoading;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (recipes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshRecipes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSaved ? Icons.favorite_border : Icons.kitchen,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(75),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSaved ? 'No saved recipes yet' : 'No recipes posted yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSaved 
                      ? 'Swipe right on recipes you like to save them here'
                      : 'Start sharing your recipes with the community!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
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
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return GestureDetector(
          onTap: () {
            _showRecipeCardOverlay(context, recipe);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
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
                // Timp în dreapta sus
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
                            if (recipe.creatorPhotoURL != null) ...[
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    recipe.creatorPhotoURL!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(75),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ] else ...[
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(75),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
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
                  height: 40,
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
                      width: 40,
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
                    onTap: () => _deleteRecipe(recipe),
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