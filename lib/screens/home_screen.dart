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
      description: 'Rețetă clasică de paste carbonara cu ou și pecorino. O rețetă autentică italiană care se prepară rapid și este delicioasă. Perfect pentru o cină în familie sau cu prietenii. Secretul este în calitatea ingredientelor și în tehnica de preparare.',
      ingredients: ['paste', 'ou', 'pecorino', 'guanciale', 'piper negru', 'sare'],
      instructions: [
        'Fierbe pastele în apă cu sare conform instrucțiunilor de pe pachet',
        'Amestecă ouăle cu pecorino și piper',
        'Prăjește guanciale până devine crocant',
        'Amestecă pastele cu sosul de ou și guanciale',
        'Servește imediat cu pecorino ras și piper negru'
      ],
      creatorId: 'user1',
      creatorName: 'Chef John',
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '2',
      title: 'Pizza Margherita',
      imageUrl: 'https://images.unsplash.com/photo-1598023696416-0193a0bcd302',
      description: 'Pizza simplă și delicioasă în stil napoletan. Cu blat subțire și crocant, sos de roșii proaspete San Marzano, mozzarella di bufala și busuioc. Coaptă la temperatură înaltă pentru un gust perfect.',
      ingredients: ['aluat de pizza', 'roșii San Marzano', 'mozzarella di bufala', 'busuioc proaspăt', 'ulei de măsline', 'sare'],
      instructions: [
        'Preîncălzește cuptorul la temperatura maximă',
        'Întinde aluatul într-un cerc subțire',
        'Adaugă sosul de roșii și sare',
        'Pune bucățele de mozzarella',
        'Coace până când marginile sunt aurii',
        'Adaugă busuioc proaspăt și ulei de măsline'
      ],
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
              centerTitle: true,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
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
