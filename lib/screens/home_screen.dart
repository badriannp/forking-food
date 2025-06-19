import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';

typedef CardBuilder = Widget? Function(BuildContext context, int index, int? realIndex);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  
  // Dummy data pentru exemplu
  final List<Recipe> recipes = [
    Recipe(
      id: '1',
      title: 'Spaghete Carbonara',
      imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3',
      description: 'Rețetă clasică de paste carbonara',
      ingredients: ['paste', 'ou', 'pecorino'],
      instructions: ['Fierbe pastele', 'Amestecă ouăle'],
      creatorId: 'user1',
      creatorName: 'Chef John',
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '2',
      title: 'Pizza Margherita',
      imageUrl: 'https://images.unsplash.com/photo-1598023696416-0193a0bcd302',
      description: 'Pizza simplă și delicioasă',
      ingredients: ['aluat', 'roșii', 'mozzarella'],
      instructions: ['Întinde aluatul', 'Adaugă sosul'],
      creatorId: 'user2',
      creatorName: 'Chef Maria',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: AppBar(
              title: Text(
                'Forking',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'EduNSWACTHand',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 28,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: CardSwiper(
                controller: controller,
                isLoop: false,
                cardsCount: recipes.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                cardBuilder: (BuildContext context, int index, int percentThresholdX, int percentThresholdY) {
                  return RecipeCard(recipe: recipes[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    // Returnăm true pentru a permite toate swipe-urile
    return true;
  }
}
