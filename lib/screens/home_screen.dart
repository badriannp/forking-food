import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  final List<Recipe> recipes = [
    Recipe(
      id: '1',
      title: 'Spaghete Carbonara',
      imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3',
      description: 'Rețetă clasică de paste carbonara cu ou și pecorino. O rețetă autentică italiană care se prepară rapid și este delicioasă.',
      ingredients: ['200g paste', '2 ouă', '50g pecorino', '50g guanciale', 'piper negru'],
      instructions: [
        InstructionStep(description: 'Fierbe pastele conform instrucțiunilor.'),
        InstructionStep(description: 'Prăjește guanciale până devine crocant.'),
        InstructionStep(description: 'Amestecă ouăle cu pecorino și piper într-un bol separat.'),
        InstructionStep(description: 'Scurge pastele și amestecă-le rapid cu guanciale și sosul de ou.'),
      ],
      totalEstimatedTime: const Duration(minutes: 20),
      tags: ['paste', 'italian', 'rapid'],
      creatorId: 'user1',
      creatorName: 'Chef John',
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '2',
      title: 'Pizza Margherita',
      imageUrl: 'https://images.unsplash.com/photo-1598023696416-0193a0bcd302',
      description: 'Pizza simplă și delicioasă în stil napoletan. Cu blat subțire și crocant, sos de roșii proaspete și mozzarella di bufala.',
      ingredients: ['1 blat de pizza', '100g sos de roșii', '125g mozzarella di bufala', 'Busuioc proaspăt'],
      instructions: [
        InstructionStep(description: 'Preîncălzește cuptorul la 250°C.'),
        InstructionStep(description: 'Întinde sosul de roșii pe blat.'),
        InstructionStep(description: 'Adaugă mozzarella și busuioc.'),
        InstructionStep(description: 'Coace timp de 10-12 minute.'),
      ],
      totalEstimatedTime: const Duration(minutes: 15),
      tags: ['pizza', 'italian', 'vegetarian'],
      creatorId: 'user2',
      creatorName: 'Chef Maria',
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '3',
      title: 'Salată Caesar',
      imageUrl: 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9',
      description: 'O salată clasică și răcoritoare, perfectă pentru un prânz ușor.',
      ingredients: ['Salată romană', 'Piept de pui la grătar', 'Crutoane', 'Parmezan', 'Sos Caesar'],
      instructions: [
        InstructionStep(description: 'Spală și taie salata.'),
        InstructionStep(description: 'Taie pieptul de pui în fâșii.'),
        InstructionStep(description: 'Amestecă toate ingredientele într-un bol mare.'),
        InstructionStep(description: 'Adaugă sosul și servește imediat.'),
      ],
      totalEstimatedTime: const Duration(minutes: 15),
      tags: ['salată', 'ușor', 'pui'],
      creatorId: 'user1',
      creatorName: 'Chef John',
      createdAt: DateTime.now(),
    ),
    Recipe(
      id: '4',
      title: 'Supă cremă de linte',
      imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3',
      description: 'O supă sățioasă și plină de nutrienți, ideală pentru o zi rece.',
      ingredients: ['250g linte roșie', '1 ceapă', '2 morcovi', '1 tulpină de țelină', 'Supă de legume'],
      instructions: [
        InstructionStep(description: 'Călește ceapa, morcovii și țelina tocate mărunt.'),
        InstructionStep(description: 'Adaugă lintea spălată și supa de legume.'),
        InstructionStep(description: 'Fierbe timp de 20-25 de minute.'),
        InstructionStep(description: 'Pasează supa cu un blender vertical până devine cremoasă.'),
      ],
      totalEstimatedTime: const Duration(minutes: 30),
      tags: ['supă', 'vegan', 'sănătos'],
      creatorId: 'user3',
      creatorName: 'Chef Ion',
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
            onPressed: () {
              // TODO: Settings
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: CardSwiper(
              scale: 0.85,
              backCardOffset: const Offset(0, .25),
              controller: controller,
              isLoop: false,
              cardsCount: recipes.length,
              onSwipe: _onSwipe,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              allowedSwipeDirection: const AllowedSwipeDirection.only(
                left: true,
                right: true,
                up: false,
                down: false,
              ),
              cardBuilder: (BuildContext context, int index, int percentThresholdX, int percentThresholdY) {
                return RecipeCard(
                  recipe: recipes[index],
                  constraints: constraints,
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    return true;
  }
}

