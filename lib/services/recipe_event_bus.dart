import 'dart:async';

/// Event bus for communication between screens when swipes happen
class RecipeEventBus {
  // Stream for swipes in home
  static final StreamController<String> _homeSwipeController = StreamController<String>.broadcast();
  static Stream<String> get homeSwipeStream => _homeSwipeController.stream;
  
  // Stream for swipes in discover
  static final StreamController<String> _discoverSwipeController = StreamController<String>.broadcast();
  static Stream<String> get discoverSwipeStream => _discoverSwipeController.stream;
  
  /// Emit an event when swipe happens in home screen
  static void emitHomeSwipe(String recipeId) {
    _homeSwipeController.add(recipeId);
  }
  
  /// Emit an event when swipe happens in discover screen
  static void emitDiscoverSwipe(String recipeId) {
    _discoverSwipeController.add(recipeId);
  }
  
  /// Close streams (called at dispose)
  static void dispose() {
    _homeSwipeController.close();
    _discoverSwipeController.close();
  }
} 