import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:forking/services/recipe_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forking/services/auth_service.dart';
import 'package:forking/services/recipe_event_bus.dart';
import 'package:forking/utils/haptic_feedback.dart';
import 'dart:async';

typedef CardBuilder = Widget? Function(BuildContext context, int index, int? realIndex);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  StreamSubscription? _discoverSwipeSubscription;
  
  // Recipe state
  List<Recipe> recipes = [];
  List<Recipe> availableRecipes = [];
  DocumentSnapshot? lastDocument;
  DateTime? lastTimestamp;
  bool hasMore = true;
  bool isLoading = false;
  bool isInitialLoading = true;
  bool hasReachedEnd = false; // Track when we've reached the end

  // Pool management constants
  static const int _minPoolSize = 5;
  static const int _swiperSize = 3;

  // Filter state
  Set<String> selectedDietaryCriteria = {};
  Duration minTime = const Duration(minutes: -1); // No limit
  Duration maxTime = const Duration(minutes: -1); // No limit

  // Available dietary criteria (loaded from database)
  List<String> availableDietaryCriteria = [];
  bool isLoadingDietaryCriteria = false;

  // Threshold tracking for haptic feedback
  bool _hasTriggeredForkInThreshold = false;
  bool _hasTriggeredForkOutThreshold = false;

  List<Recipe> get recipesToShow => recipes;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
    _loadDietaryCriteria();
    
    // Listen to swipe events from discover screen
    _discoverSwipeSubscription = RecipeEventBus.discoverSwipeStream.listen((recipeId) {
      _removeRecipeFromHome(recipeId);
    });
  }

  /// Load initial recipes from Firebase
  Future<void> _loadInitialRecipes() async {
    if (!mounted) return;
    
    setState(() {
      isInitialLoading = true;
      hasReachedEnd = false; // Reset when loading new recipes
      recipes.clear(); // Clear existing recipes
      availableRecipes.clear(); // Clear available pool
      lastDocument = null; // Reset pagination
      lastTimestamp = null; // Reset timestamp pagination
      hasMore = true; // Reset hasMore
    });

    try {
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      final result = await _recipeService.getRecipesForFeed(
        userId: userId,
        dietaryCriteria: selectedDietaryCriteria.isEmpty ? null : selectedDietaryCriteria.toList(),
        minTime: minTime.inMinutes == -1 ? null : minTime,
        maxTime: maxTime.inMinutes == -1 ? null : maxTime,
      );
      

      
      if (mounted) {
        setState(() {
          availableRecipes = result.recipes;
          lastDocument = result.lastDocument;
          lastTimestamp = result.lastTimestamp; // Save timestamp for pagination
          hasMore = result.hasMore;
          isInitialLoading = false;
        });
        
        if (recipes.isEmpty) {
          _populateSwiper();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isInitialLoading = false;
        });
      }
    }
  }

  void _populateSwiper() {
    if (availableRecipes.isEmpty) {
      if (recipes.isEmpty && !hasMore) {
        setState(() {
          hasReachedEnd = true;
        });
      }
      return;
    }
    
    List<Recipe> recipesForSwiper = availableRecipes.take(_swiperSize).toList();
    
    setState(() {
      recipes = recipesForSwiper;
      availableRecipes = availableRecipes.skip(_swiperSize).toList();
    });
    
    if (recipes.isNotEmpty) {
      setState(() {
        hasReachedEnd = false;
      });
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (isLoading || !hasMore) {
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      RecipePaginationResult result = await _recipeService.getRecipesForFeed(
        userId: userId,
        lastDocument: lastDocument,
        lastTimestamp: lastTimestamp, // Use timestamp-based pagination
        limit: 3,
        dietaryCriteria: selectedDietaryCriteria.isNotEmpty ? selectedDietaryCriteria.toList() : null,
        minTime: minTime.inMinutes != -1 ? minTime : null,
        maxTime: maxTime.inMinutes != -1 ? maxTime : null,
      );

      if (mounted) {
        setState(() {
          if (result.recipes.isNotEmpty) {
            // Evită duplicatele în pool
            Set<String> existingIds = availableRecipes.map((r) => r.id).toSet();
            List<Recipe> newRecipes = result.recipes.where((r) => !existingIds.contains(r.id)).toList();
            
            availableRecipes.addAll(newRecipes); // Adaugă în pool
            lastDocument = result.lastDocument;
            lastTimestamp = result.lastTimestamp; // Save timestamp for pagination
            hasMore = result.hasMore;
          } else {
            // No more recipes available
            hasMore = false;
            // Check if we should show "no more recipes" message
            if (availableRecipes.isEmpty && recipes.isEmpty) {
              hasReachedEnd = true;
            }
          }
          isLoading = false;
        });
        
        // Populează swiper-ul doar dacă este gol
        if (recipes.isEmpty) {
          _populateSwiper();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          // Don't set hasMore to false on error, try again later
        });
      }
    }
  }

  /// Maintain pool size by loading more recipes if needed
  void _maintainPoolSize() {
    if (availableRecipes.length < _minPoolSize && hasMore && !isLoading) {
      _loadMoreRecipes();
    }
  }

  /// Reload recipes when filters change
  Future<void> _reloadRecipesWithFilters() async {
    setState(() {
      isLoading = true;
      isInitialLoading = true;
      recipes.clear();
      availableRecipes.clear();
      lastDocument = null;
      lastTimestamp = null; // Reset timestamp pagination
      hasMore = true;
      hasReachedEnd = false;
    });

    try {
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      RecipePaginationResult result = await _recipeService.getRecipesForFeed(
        userId: userId,
        limit: 3,
        dietaryCriteria: selectedDietaryCriteria.isNotEmpty ? selectedDietaryCriteria.toList() : null,
        minTime: minTime.inMinutes != -1 ? minTime : null,
        maxTime: maxTime.inMinutes != -1 ? maxTime : null,
      );

      if (mounted) {
        setState(() {
          availableRecipes = result.recipes;
          lastDocument = result.lastDocument;
          lastTimestamp = result.lastTimestamp; // Save timestamp for pagination
          hasMore = result.hasMore;
          isLoading = false;
          isInitialLoading = false;
        });
        
        _populateSwiper();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isInitialLoading = false;
        });
      }
    }
  }

  /// Load dietary criteria from database
  Future<void> _loadDietaryCriteria() async {
    setState(() {
      isLoadingDietaryCriteria = true;
    });
    
    try {
      final criteria = await _recipeService.getAllDietaryCriteria();
      if (mounted) {
        setState(() {
          availableDietaryCriteria = criteria;
          isLoadingDietaryCriteria = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDietaryCriteria = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _discoverSwipeSubscription?.cancel();
    super.dispose();
  }

  /// Remove recipe from home when it's swiped in discover
  void _removeRecipeFromHome(String recipeId) {
    setState(() {
      recipes.removeWhere((recipe) => recipe.id == recipeId);
      availableRecipes.removeWhere((recipe) => recipe.id == recipeId);
      _maintainPoolSize();
      _promoteRecipeFromPool();
    });
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
            Icons.library_add_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          onPressed: () {
            HapticUtils.triggerSelection();
            // Navigate to add recipe screen
            Navigator.pushNamed(context, '/add-recipe');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              HapticUtils.triggerSelection();
              _showFilterModal();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Show loading state
          if (isInitialLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: recipesToShow.isEmpty || hasReachedEnd
                ? RefreshIndicator(
                    onRefresh: () async {
                      await _refreshRecipes();
                      HapticUtils.triggerSelection();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: _buildNoRecipesView(),
                      ),
                    ),
                  )
                : Stack(
                        children: [
                          CardSwiper(
                            scale: 1,
                            numberOfCardsDisplayed: recipesToShow.length == 1 ? 1 : 2,
                            backCardOffset: const Offset(0, 0),
                            controller: controller,
                            isLoop: false,
                            cardsCount: recipesToShow.length,
                            onSwipe: _onSwipe,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            allowedSwipeDirection: const AllowedSwipeDirection.only(
                              left: true,
                              right: true,
                              up: false,
                              down: false,
                            ),
                            cardBuilder: (BuildContext context, int index, int percentThresholdX, int percentThresholdY) {
                              // Trigger haptic feedback when crossing thresholds
                              if (percentThresholdX > 200 && !_hasTriggeredForkInThreshold) {
                                _hasTriggeredForkInThreshold = true;
                                HapticUtils.triggerHeavyImpact();
                              } else if (percentThresholdX < 150 && percentThresholdX > 0 && _hasTriggeredForkInThreshold) {
                                _hasTriggeredForkInThreshold = false;
                                HapticUtils.triggerHeavyImpact();
                              }
                              
                              if (percentThresholdX < -200 && !_hasTriggeredForkOutThreshold) {
                                _hasTriggeredForkOutThreshold = true;
                                HapticUtils.triggerHeavyImpact();
                              } else if (percentThresholdX > -150 && percentThresholdX < 0 && _hasTriggeredForkOutThreshold) {
                                _hasTriggeredForkOutThreshold = false;
                                HapticUtils.triggerHeavyImpact();
                              }
                              
                              return Stack(
                                children: [
                                  RecipeCard(
                                    key: ValueKey('recipe_${recipesToShow[index].id}_$index'),
                                    recipe: recipesToShow[index],
                                    constraints: constraints,
                                  ),
                                  // FORK IN overlay (swipe dreapta)
                                  if (percentThresholdX > 150)
                                    Positioned(
                                      top: 80,
                                      left: 20,
                                      child: Transform.rotate(
                                        angle: -0.785/2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.green, width: 2),
                                            color: Colors.green.withAlpha(100),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.thumb_up,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "FORK IN",
                                                style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  // FORK OUT overlay (swipe stânga)
                                  if (percentThresholdX < -150)
                                    Positioned(
                                      top: 80,
                                      right: 20,
                                      child: Transform.rotate(
                                        angle: 0.785/2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.red, width: 2),
                                            color: Colors.red.withAlpha(100),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.thumb_down,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "FORK OUT",
                                                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          // Loading indicator for pagination
                          if (isLoading)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Loading more recipes...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          );
        },
      ),
    );
  }

  /// Refresh recipes - reset everything and start over
  Future<void> _refreshRecipes() async {
    setState(() {
      hasReachedEnd = false;
      hasMore = true;
      lastDocument = null;
      lastTimestamp = null; // Reset timestamp pagination
      recipes.clear();
      availableRecipes.clear();
    });
    
    await _loadInitialRecipes();
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    
    // Reset threshold tracking for next card
    _hasTriggeredForkInThreshold = false;
    _hasTriggeredForkOutThreshold = false;
    
    // Save swipe action to Firebase
    if (previousIndex < recipesToShow.length) {
      final recipe = recipesToShow[previousIndex];
      final swipeDirection = direction == CardSwiperDirection.left 
          ? SwipeDirection.left 
          : SwipeDirection.right;
      
      // Emit event for discover screen
      RecipeEventBus.emitHomeSwipe(recipe.id);

      // Save swipe action to Firebase
      final String? userId = _authService.userId;
      if (userId == null) return false;
      
      _recipeService.saveSwipe(
        userId: userId,
        recipeId: recipe.id,
        direction: swipeDirection,
      );
    }

    // Check if we've reached the end of swiper
    if (currentIndex == null) {
      if (availableRecipes.isEmpty && !hasMore) {
        setState(() {
          hasReachedEnd = true;
        });
      } else if (availableRecipes.isNotEmpty) {
        _promoteRecipeFromPool();
      } else if (hasMore) {
        _loadMoreRecipes();
      }
      return true;
    }

    _promoteRecipeFromPool();

    _maintainPoolSize();
    
    return true;
  }

  void _promoteRecipeFromPool() {
    if (availableRecipes.isEmpty) {
      if (recipes.isEmpty && !hasMore) {
        setState(() {
          hasReachedEnd = true;
        });
      }
      return;
    }

    Recipe promotedRecipe = availableRecipes.first;
    
    setState(() {
      recipes.add(promotedRecipe);
      availableRecipes.removeAt(0);
    });
    
    _maintainPoolSize();
  }

  void _showFilterModal() {
    // Save current filter state
    final prevDietary = Set<String>.from(selectedDietaryCriteria);
    final prevMinTime = minTime;
    final prevMaxTime = maxTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _buildFilterBottomSheet(),
    ).then((result) {
      // If user didn't press Apply, revert to previous state
      if (result != 'apply') {
        setState(() {
          selectedDietaryCriteria = prevDietary;
          minTime = prevMinTime;
          maxTime = prevMaxTime;
        });
      }
    });
  }

  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        HapticUtils.triggerSelection();
                        setState(() {
                          selectedDietaryCriteria.clear();
                          minTime = const Duration(minutes: -1);
                          maxTime = const Duration(minutes: -1);
                        });
                        setModalState(() {});
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dietary Criteria Section
                      Text(
                        'Dietary Criteria',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableDietaryCriteria.map((criteria) {
                          final isSelected = selectedDietaryCriteria.contains(criteria);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedDietaryCriteria.remove(criteria);
                                } else {
                                  selectedDietaryCriteria.add(criteria);
                                }
                              });
                              setModalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                criteria,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Time Range Section
                      Text(
                        'Preparation Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Min Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minimum Time',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showTimePicker(context, true, setModalState),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          minTime.inMinutes == -1 ? '-' : '${minTime.inHours}h ${minTime.inMinutes % 60}min',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maximum Time',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showTimePicker(context, false, setModalState),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          maxTime.inMinutes == -1 ? '-' : '${maxTime.inHours}h ${maxTime.inMinutes % 60}min',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // Apply Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticUtils.triggerSelection();
                      Navigator.pop(context, 'apply');
                      await _reloadRecipesWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showTimePicker(BuildContext context, bool isMinTime, Function setModalState) {
    int selectedHours = isMinTime ? minTime.inHours : maxTime.inHours;
    int selectedMinutes = isMinTime ? minTime.inMinutes % 60 : maxTime.inMinutes % 60;
    bool isNoLimit = isMinTime ? minTime.inMinutes == -1 : maxTime.inMinutes == -1;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            // Calculate min time in minutes for max time picker
            final minTimeInMinutes = minTime.inMinutes == -1 ? 0 : minTime.inMinutes;
            
            // Check if current selection is valid for max time
            bool isSelectionValid = true;
            if (!isMinTime && !isNoLimit) {
              final currentTimeInMinutes = selectedHours * 60 + selectedMinutes;
              isSelectionValid = currentTimeInMinutes >= minTimeInMinutes;
            }
            
            return SizedBox(
              height: 250,
              child: Column(
                children: [
                  Container(
                    height: 50,
                    color: Colors.grey[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context, 'cancel');
                          },
                        ),
                        Text(
                          isMinTime ? 'Min' : 'Max',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: isSelectionValid ? () => Navigator.pop(context) : null,
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(initialItem: isNoLimit ? 0 : selectedHours + 1),
                            onSelectedItemChanged: (value) {
                              if (value == 0) {
                                isNoLimit = true;
                              } else {
                                final wasNoLimit = isNoLimit;
                                isNoLimit = false;
                                selectedHours = value - 1;
                                // Reset minutes to 0 only when transitioning from "-" to a specific hour
                                if (wasNoLimit) {
                                  selectedMinutes = 0;
                                }
                              }
                              setPickerState(() {});
                            },
                            children: isMinTime 
                                ? [
                                    const Center(child: Text('-')),
                                    ...List.generate(25, (i) => Center(child: Text('$i h'))),
                                  ]
                                : [
                                    const Center(child: Text('-')),
                                    ...List.generate(25, (i) {
                                      final currentTimeInMinutes = i * 60;
                                      final isDisabled = currentTimeInMinutes < minTimeInMinutes;
                                      return Center(
                                        child: Text(
                                          '$i h',
                                          style: TextStyle(
                                            color: isDisabled 
                                                ? Colors.grey.withOpacity(0.3)
                                                : null,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(initialItem: isNoLimit ? 0 : selectedMinutes + 1),
                            onSelectedItemChanged: (value) {
                              if (value == 0) {
                                isNoLimit = true;
                              } else {
                                isNoLimit = false;
                                selectedMinutes = value - 1;
                              }
                              setPickerState(() {});
                            },
                            children: isMinTime 
                                ? [
                                    const Center(child: Text('-')),
                                    ...List.generate(60, (i) => Center(child: Text('$i min'))),
                                  ]
                                : [
                                    const Center(child: Text('-')),
                                    ...List.generate(60, (i) {
                                      final currentTimeInMinutes = selectedHours * 60 + i;
                                      final isDisabled = currentTimeInMinutes < minTimeInMinutes;
                                      return Center(
                                        child: Text(
                                          '$i min',
                                          style: TextStyle(
                                            color: isDisabled 
                                                ? Colors.grey.withOpacity(0.3)
                                                : null,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result == 'cancel' && !isMinTime) {
        // Reset max time to no limit when cancel is pressed
        setState(() {
          maxTime = const Duration(minutes: -1);
        });
        setModalState(() {});
      } else {
        // Apply the selected time when modal is closed
        final newDuration = isNoLimit 
            ? const Duration(minutes: -1) // Special value for no limit
            : Duration(hours: selectedHours, minutes: selectedMinutes);
        
        setState(() {
          if (isMinTime) {
            minTime = newDuration;
          } else {
            maxTime = newDuration;
          }
        });
        setModalState(() {});
        
        // Auto-open max time picker if min time becomes greater than max time
        if (isMinTime && 
            newDuration.inMinutes != -1 && 
            maxTime.inMinutes != -1 && 
            newDuration.inMinutes > maxTime.inMinutes) {
          // Small delay to ensure current modal is closed
          Future.delayed(const Duration(milliseconds: 300), () {
            _showTimePicker(context, false, setModalState);
          });
        }
      }
    });
  }

  Widget _buildNoRecipesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'No recipes found',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

