import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:forking/services/recipe_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forking/services/auth_service.dart';

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
  
  // Recipe state
  List<Recipe> recipes = [];
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  bool isLoading = false;
  bool isInitialLoading = true;

  // Filter state
  Set<String> selectedDietaryCriteria = {};
  Duration minTime = const Duration(minutes: -1); // No limit
  Duration maxTime = const Duration(minutes: -1); // No limit

  // Available dietary criteria
  final List<String> availableDietaryCriteria = [
    'Vegan',
    'Vegetarian',
    'Gluten Free',
    'Lactose Free',
    'Dairy Free',
    'Nut Free',
    'Low Carb',
    'Keto',
    'Paleo',
    'Halal',
    'Kosher',
    'Low Sodium',
    'Sugar Free',
    'Organic',
  ];

  // Recipes to show (no more client-side filtering)
  List<Recipe> get recipesToShow => recipes;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
  }

  /// Load initial recipes from Firebase
  Future<void> _loadInitialRecipes() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
      isInitialLoading = true;
    });

    try {

      final String? userId = _authService.userId;
      if (userId == null) return;
      
      RecipePaginationResult result = await _recipeService.getRecipesForFeed(
        userId: userId,
        limit: 20,
        dietaryCriteria: selectedDietaryCriteria.isNotEmpty ? selectedDietaryCriteria.toList() : null,
        minTime: minTime.inMinutes != -1 ? minTime : null,
        maxTime: maxTime.inMinutes != -1 ? maxTime : null,
      );

      setState(() {
        recipes = result.recipes;
        lastDocument = result.lastDocument;
        hasMore = result.hasMore;
        isLoading = false;
        isInitialLoading = false;
      });
    } catch (e) {
      print('Error loading initial recipes: $e');
      setState(() {
        isLoading = false;
        isInitialLoading = false;
      });
    }
  }

  /// Load more recipes when user is near the end
  Future<void> _loadMoreRecipes() async {
    if (isLoading || !hasMore || lastDocument == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // For now, use a placeholder user ID - in real app, get from AuthService
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      RecipePaginationResult result = await _recipeService.getRecipesForFeed(
        userId: userId,
        lastDocument: lastDocument,
        limit: 20,
        dietaryCriteria: selectedDietaryCriteria.isNotEmpty ? selectedDietaryCriteria.toList() : null,
        minTime: minTime.inMinutes != -1 ? minTime : null,
        maxTime: maxTime.inMinutes != -1 ? maxTime : null,
      );

      setState(() {
        recipes.addAll(result.recipes);
        lastDocument = result.lastDocument;
        hasMore = result.hasMore;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading more recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Check if we need to load more recipes
  void _checkAndLoadMore(int currentIndex) {
    if (recipesToShow.isEmpty) return;
    
    // Load more when user is 3 cards away from the end
    if (currentIndex >= recipesToShow.length - 3 && hasMore && !isLoading) {
      _loadMoreRecipes();
    }
  }

  /// Reload recipes when filters change
  Future<void> _reloadRecipesWithFilters() async {
    setState(() {
      isLoading = true;
      isInitialLoading = true;
      recipes.clear();
      lastDocument = null;
      hasMore = true;
    });

    try {
      // For now, use a placeholder user ID - in real app, get from AuthService
      final String? userId = _authService.userId;
      if (userId == null) return;
      
      RecipePaginationResult result = await _recipeService.getRecipesForFeed(
        userId: userId,
        limit: 20,
        dietaryCriteria: selectedDietaryCriteria.isNotEmpty ? selectedDietaryCriteria.toList() : null,
        minTime: minTime.inMinutes != -1 ? minTime : null,
        maxTime: maxTime.inMinutes != -1 ? maxTime : null,
      );

      setState(() {
        recipes = result.recipes;
        lastDocument = result.lastDocument;
        hasMore = result.hasMore;
        isLoading = false;
        isInitialLoading = false;
      });
    } catch (e) {
      print('Error reloading recipes with filters: $e');
      setState(() {
        isLoading = false;
        isInitialLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showFilterModal,
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
            child: recipesToShow.isEmpty
                ? _buildNoRecipesView()
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
                              return RecipeCard(
                                recipe: recipesToShow[index],
                                constraints: constraints,
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

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final actualCurrentIndex = currentIndex ?? 0;
    
    setState(() {
      // currentIndex is already handled above
    });
    
    // Check if we need to load more recipes
    _checkAndLoadMore(actualCurrentIndex);
    
    // Save swipe action to Firebase
    if (actualCurrentIndex < recipesToShow.length) {
      final recipe = recipesToShow[actualCurrentIndex];
      final swipeDirection = direction == CardSwiperDirection.left 
          ? SwipeDirection.left 
          : SwipeDirection.right;
      
      // For now, use a placeholder user ID - in real app, get from AuthService
      final String? userId = _authService.userId;
      if (userId == null) return false;
      
      _recipeService.saveSwipe(
        userId: userId,
        recipeId: recipe.id,
        direction: swipeDirection,
      );
    }
    
    return true;
  }

  void _showFilterModal() {
    // Salvează starea curentă a filtrelor
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
      // Dacă userul nu a apăsat Apply, revino la starea anterioară
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
                        setState(() {
                          selectedDietaryCriteria.clear();
                          minTime = const Duration(minutes: -1);
                          maxTime = const Duration(minutes: -1);
                        });
                        setModalState(() {});
                        await _reloadRecipesWithFilters();
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

