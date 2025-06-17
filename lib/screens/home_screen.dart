import 'package:flutter/material.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:forking/models/recipe.dart';
import 'package:swipe_cards/swipe_cards.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SwipeItem> _swipeItems = [];
  MatchEngine? _matchEngine;
  List<Recipe> recipes = []; // TODO: Load from Firestore

  @override
  void initState() {
    super.initState();
    // TODO: Load recipes from Firestore
    // For now, using dummy data
    recipes = [
      Recipe(
        id: '1',
        title: 'Pasta Carbonara',
        imageUrl: 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?q=80&w=1287&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        description: 'Classic Italian pasta dish with eggs, cheese, pancetta, and black pepper.',
        ingredients: ['Spaghetti', 'Eggs', 'Pecorino Romano', 'Pancetta', 'Black Pepper'],
        instructions: ['Boil pasta', 'Cook pancetta', 'Mix eggs and cheese', 'Combine all'],
        creatorId: 'user1',
        creatorName: 'Chef John',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '2',
        title: 'Chicken Tikka Masala',
        imageUrl: 'https://images.unsplash.com/photo-1694579740719-0e601c5d2437?q=80&w=1287&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        description: 'Creamy curry dish with tender chicken pieces in a spiced tomato sauce.',
        ingredients: ['Chicken', 'Yogurt', 'Tomato Sauce', 'Cream', 'Spices'],
        instructions: ['Marinate chicken', 'Grill chicken', 'Make sauce', 'Combine and simmer'],
        creatorId: 'user2',
        creatorName: 'Chef Maria',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '3',
        title: 'Beef Wellington',
        imageUrl: 'https://images.unsplash.com/photo-1746211224472-2f122b686885?q=80&w=2670&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        description: 'Beef fillet wrapped in puff pastry with mushroom duxelles and prosciutto.',
        ingredients: ['Beef Fillet', 'Puff Pastry', 'Mushrooms', 'Prosciutto', 'Mustard'],
        instructions: ['Sear beef', 'Make duxelles', 'Wrap in prosciutto', 'Wrap in pastry', 'Bake'],
        creatorId: 'user3',
        creatorName: 'Chef Gordon',
        createdAt: DateTime.now(),
      ),
      Recipe(
        id: '4',
        title: 'Pad Thai',
        imageUrl: 'https://images.unsplash.com/photo-1637806930600-37fa8892069d?q=80&w=1285&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        description: 'Stir-fried rice noodles with eggs, tofu, and peanuts in a sweet and sour sauce.',
        ingredients: ['Rice Noodles', 'Tofu', 'Peanuts', 'Tamarind', 'Palm Sugar'],
        instructions: ['Soak noodles', 'Stir-fry ingredients', 'Add sauce', 'Garnish'],
        creatorId: 'user4',
        creatorName: 'Chef Som',
        createdAt: DateTime.now(),
      ),
    ];

    _loadCards();
  }

  void _loadCards() {
    for (var recipe in recipes) {
      _swipeItems.add(
        SwipeItem(
          content: recipe,
          likeAction: () {
            // Handle like action
          },
          nopeAction: () {
            // Handle nope action
          },
          superlikeAction: () {
            // Handle superlike action
          },
        ),
      );
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forking',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'EduNSWACTHand',
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: recipes.isEmpty
          ? const Center(
              child: Text(
                'No recipes available',
                style: TextStyle(fontSize: 18),
              ),
            )
          : _matchEngine == null
              ? const Center(child: CircularProgressIndicator())
              : SwipeCards(
                  matchEngine: _matchEngine!,
                  itemBuilder: (BuildContext context, int index) {
                    return RecipeCard(recipe: _swipeItems[index].content as Recipe);
                  },
                  onStackFinished: () {
                    // Handle when all cards are swiped
                    setState(() {
                      recipes = [];
                    });
                  },
                  itemChanged: (SwipeItem item, int index) {
                    // Handle when a card is swiped
                  },
                  fillSpace: true,
                ),
    );
  }
} 