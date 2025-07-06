import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:forking/widgets/creator_avatar.dart';
import 'package:forking/services/recipe_service.dart';
import 'package:forking/services/auth_service.dart';
import 'package:forking/services/recipe_event_bus.dart';
import 'package:forking/utils/haptic_feedback.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  StreamSubscription? _homeSwipeSubscription;
  
  // Today's favorites
  List<Recipe> todayFavorites = [];
  bool isLoadingToday = true;
  
  // Personalized recommendations
  List<Recipe> recommendations = [];
  bool isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTodayFavorites();
    _loadRecommendations();
    
    // Listen to swipe events from home screen
    _homeSwipeSubscription = RecipeEventBus.homeSwipeStream.listen((recipeId) {
      _removeRecipeFromRecommendations(recipeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _homeSwipeSubscription?.cancel();
    super.dispose();
  }

  /// Load today's leaderboard
  Future<void> _loadTodayFavorites() async {
    setState(() {
      isLoadingToday = true;
    });

    try {
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      // Get today's leaderboard (top 3 most liked recipes today)
      final recipes = await _recipeService.getTodayLeaderboard(limit: 3);

      setState(() {
        todayFavorites = recipes;
        isLoadingToday = false;
      });
    } catch (e) {
      setState(() {
        isLoadingToday = false;
      });
    }
  }

  /// Load personalized recommendations
  Future<void> _loadRecommendations() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      // Get personalized recommendations using the scoring algorithm
      final recipes = await _recipeService.getPersonalizedRecommendations(
        userId: userId,
        limit: 8,
      );

      setState(() {
        recommendations = recipes;
        isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRecommendations = false;
      });
    }
  }

  /// when a recipe is swiped in home, refresh the list
  void _removeRecipeFromRecommendations(String recipeId) {
    _loadRecommendations();
  }

  /// Build action button for overlay
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
    bool isSelected = false,
    IconData? selectedIcon,
  }) {
    final bool isEnabled = !isDisabled;
    final Color buttonColor = isDisabled 
        ? color.withAlpha(80) 
        : isSelected 
            ? color 
            : color.withAlpha(150);
    
    final IconData displayIcon = isSelected && selectedIcon != null 
        ? selectedIcon 
        : icon;
    
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          border: isSelected 
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDisabled ? 0.1 : 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          displayIcon,
          color: isDisabled ? Colors.white.withAlpha(120) : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// Handle fork-in action (save recipe)
  void _handleForkIn(Recipe recipe) async {
    // Trigger haptic feedback
    HapticUtils.triggerSuccess();
    
    // Save swipe in Firebase
    final String? userId = _authService.userId;
    if (userId != null) {
      await _recipeService.saveSwipe(
        userId: userId,
        recipeId: recipe.id,
        direction: SwipeDirection.right,
      );
    }
    
    // Remove from local list
    _removeRecipeFromRecommendations(recipe.id);
    
    // Emit event for home screen
    RecipeEventBus.emitDiscoverSwipe(recipe.id);
    
    // Close overlay
    Navigator.of(context).pop();
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe.title} saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Handle fork-out action (skip recipe)
  void _handleForkOut(Recipe recipe) async {
    // Trigger haptic feedback
    HapticUtils.triggerSelection();
    
    // Save swipe in Firebase
    final String? userId = _authService.userId;
    if (userId != null) {
      await _recipeService.saveSwipe(
        userId: userId,
        recipeId: recipe.id,
        direction: SwipeDirection.left,
      );
    }
    
    // Remove from local list
    _removeRecipeFromRecommendations(recipe.id);
    
    // Emit event for home screen
    RecipeEventBus.emitDiscoverSwipe(recipe.id);
    
    // Close overlay
    Navigator.of(context).pop();
  }

  /// Check if a recipe has been swiped and get the swipe direction
  Future<Map<String, dynamic>> _getSwipeState(String recipeId) async {
    try {
      final String? userId = _authService.userId;
      if (userId == null) return {'isSwiped': false, 'direction': null};
      
      final swipesDoc = await FirebaseFirestore.instance
          .collection('swipes')
          .doc(userId)
          .get();
      
      if (!swipesDoc.exists || swipesDoc.data() == null || swipesDoc.data()!['swipedRecipes'] == null) {
        return {'isSwiped': false, 'direction': null};
      }
      
      final swipedRecipes = swipesDoc.data()!['swipedRecipes'] as Map<String, dynamic>;
      final swipeDirection = swipedRecipes[recipeId] as String?;
      
      return {
        'isSwiped': swipeDirection != null,
        'direction': swipeDirection,
      };
    } catch (e) {
      return {'isSwiped': false, 'direction': null};
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
        leading: IconButton(
          icon: Icon(
            Icons.my_library_add_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          onPressed: () {
            HapticUtils.triggerSelection();
            // Navigate to add recipe screen
            Navigator.pushNamed(context, '/add-recipe');
          },
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            indicatorColor: Theme.of(context).colorScheme.primary,
            splashFactory: NoSplash.splashFactory,
            dividerHeight: 0.125,
            dividerColor: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            isScrollable: false,
            indicatorAnimation: TabIndicatorAnimation.elastic,
            tabs: const [
              Tab(text: "Today's Top"),
              Tab(text: 'ForkYou'),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await _loadTodayFavorites();
                    HapticUtils.triggerSelection();
                  },
                  child: _buildTodayFavoritesTab(),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    await _loadRecommendations();
                    HapticUtils.triggerSelection();
                  },
                  child: _buildRecommendationsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFavoritesTab() {
    if (isLoadingToday) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3, // Always show 3 positions
      itemBuilder: (context, index) {
        final rank = index + 1;
        
        // Check if we have a recipe for this position
        if (index < todayFavorites.length) {
          final recipe = todayFavorites[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildLeaderboardCard(recipe, rank),
          );
        } else {
          // Show empty card for missing position
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildEmptyLeaderboardCard(rank),
          );
        }
      },
    );
  }

  Widget _buildLeaderboardCard(Recipe recipe, int rank) {
    return GestureDetector(
      onTap: () {
        // HapticUtils.triggerSelection();
        _showRecipeCardOverlay(context, recipe);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 60,
              height: 120,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getRankIcon(rank),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recipe image
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Recipe info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CreatorAvatar(
                          imageUrl: recipe.creatorPhotoURL,
                          size: 20,
                          borderColor: null,
                          fallbackColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recipe.creatorName ?? 'Unknown Chef',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fork-ins
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          recipe.forkInCount.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'fork-ins',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.workspace_premium; // Premium
      case 3:
        return Icons.star; // Star
      default:
        return Icons.favorite;
    }
  }

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

  void _showRecipeCardOverlay(BuildContext context, Recipe recipe) async {
    // Get swipe state for this recipe
    final swipeState = await _getSwipeState(recipe.id);
    final bool isSwiped = swipeState['isSwiped'] as bool;
    final String? swipeDirection = swipeState['direction'] as String?;
    
    if (!context.mounted) return;
    
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
              // Action buttons
              Positioned(
                bottom: 300,
                right: 15,
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: () {
                    HapticUtils.triggerSelection();
                    _handleForkOut(recipe);
                  },
                  isDisabled: isSwiped,
                  isSelected: isSwiped && swipeDirection == 'left',
                  selectedIcon: Icons.check,
                ),
              ),
              Positioned(
                bottom: 420,
                right: 15,
                child: _buildActionButton(
                  icon: Icons.restaurant,
                  color: Colors.green,
                  onTap: () {
                    HapticUtils.triggerSelection();
                    _handleForkIn(recipe);
                  },
                  isDisabled: isSwiped,
                  isSelected: isSwiped && swipeDirection == 'right',
                  selectedIcon: Icons.check,
                ),
              ),
              // Close button
              Positioned(
                top: 12,
                right: 12,
                child: _buildActionButton(
                  icon: Icons.close,
                  color: Colors.grey,
                  onTap: () {
                    HapticUtils.triggerSelection();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (isLoadingRecommendations) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (recommendations.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recommend,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'There\'s nothing here',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Check later for more recommendations',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recipe = recommendations[index];
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
                // Title in bottom
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLeaderboardCard(int rank) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getRankIcon(rank),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Empty image placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),
          
          // Empty info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 