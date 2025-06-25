import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  
  late final List<Recipe> recipes;

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

  // Filtered recipes
  List<Recipe> get filteredRecipes {
    return recipes.where((recipe) {
      // Filter by dietary criteria
      if (selectedDietaryCriteria.isNotEmpty) {
        final recipeCriteria = Set<String>.from(recipe.dietaryCriteria);
        final hasAllCriteria = selectedDietaryCriteria.every((criteria) => recipeCriteria.contains(criteria));
        if (!hasAllCriteria) {
          return false;
        }
      }
      // Filter by time range
      final recipeTime = recipe.totalEstimatedTime.inMinutes;
      if (minTime.inMinutes != -1 && recipeTime < minTime.inMinutes) {
        return false;
      }
      if (maxTime.inMinutes != -1 && recipeTime > maxTime.inMinutes) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    recipes = [
      Recipe(
        id: '1',
        title: 'Tiramisu Clasic',
        imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9',
        description: 'Un desert italian clasic cu cafea, mascarpone și biscuiți savoiardi. Perfect pentru ocazii speciale.',
        ingredients: [
          '6 ouă',
          '150g zahăr',
          '500g mascarpone',
          '300ml cafea tare',
          '200g biscuiți savoiardi',
          'Cacao pudră pentru decor'
        ],
        instructions: [
          InstructionStep(
            description: 'Separe albușurile de gălbenușurile ouălor. Într-un bol mare, bate gălbenușurile cu jumătate din zahăr până devin spumoase și deschise la culoare.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Adaugă mascarpone-ul la gălbenușuri și amestecă delicat până se combină perfect. Asigură-te că nu bate prea tare pentru a nu rupe crema.',
          ),
          InstructionStep(
            description: 'Într-un alt bol curat, bate albușurile cu restul de zahăr până formează vârfuri ferme. Aceasta este partea cea mai importantă pentru textura finală.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Încorporează delicat albușurile în amestecul de mascarpone, folosind o mișcare de jos în sus pentru a păstra aerul din albușuri.',
          ),
          InstructionStep(
            description: 'Scufundă rapid biscuiții savoiardi în cafea și aranjează-i într-un strat pe fundul vasului. Nu îi ține prea mult în cafea pentru a nu se destrăma.',
            mediaUrl: 'https://images.unsplash.com/photo-1515669097368-22e68427d265',
          ),
          InstructionStep(
            description: 'Varsă jumătate din crema de mascarpone peste biscuiți și nivelează suprafața. Repetă cu un al doilea strat de biscuiți și cremă.',
          ),
          InstructionStep(
            description: 'După ultimul strat de cremă, acoperă cu folie de plastic și lasă la frigider cel puțin 4 ore, ideal peste noapte.',
          ),
          InstructionStep(
            description: 'Înainte de servire, presară generos cacao pudră pe suprafață. Taie în porții și servește rece.',
            mediaUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 45),
        tags: ['desert', 'italian', 'cafea', 'mascarpone'],
        creatorId: 'user4',
        creatorName: 'Chef Elena',
        createdAt: DateTime.now(),
        dietaryCriteria: ['Gluten Free'],
      ),
      Recipe(
        id: '2',
        title: 'Sushi Roll California',
        imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
        description: 'Sushi roll clasic cu crab, avocado și castraveți. Perfect pentru începători în arta sushi-ului.',
        ingredients: [
          '2 căni orez pentru sushi',
          '4 foi nori',
          '200g crab stick',
          '1 avocado',
          '1 castravețe',
          'Wasabi și gari pentru servire'
        ],
        instructions: [
          InstructionStep(
            description: 'Pune o foaie de nori pe bambusul pentru sushi cu partea lucioasă în jos. Umezește-ți mâinile cu apă pentru a evita lipirea orezului.',
            mediaUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
          ),
          InstructionStep(
            description: 'Întinde orezul pe nori, lăsând aproximativ 1 cm liber la partea de sus. Asigură-te că orezul este distribuit uniform.',
          ),
          InstructionStep(
            description: 'Pune ingredientele în centrul orezului: crab stick, avocado și castravețe tăiate în fâșii. Nu pune prea multe ingrediente.',
          ),
          InstructionStep(
            description: 'Ridică marginea de jos a bambusului și începe să rulezi nori-ul, apăsând ușor pentru a forma un cilindru compact.',
          ),
          InstructionStep(
            description: 'Umezește marginea liberă de nori cu apă și termină de rulat. Apasă ușor pentru a sigila roll-ul.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Cu un cuțit foarte ascuțit, taie roll-ul în 6-8 bucăți. Umezește cuțitul între tăieturi pentru a obține tăieturi curate.',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 30),
        tags: ['sushi', 'japonez', 'pescuit', 'raw'],
        creatorId: 'user5',
        creatorName: 'Chef Yuki',
        createdAt: DateTime.now(),
        dietaryCriteria: ['Vegetarian'],
      ),
      Recipe(
        id: '3',
        title: 'Pasta Bolognese',
        imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
        description: 'Sos bolognese clasic cu carne de vită, roșii și parmezan. O rețetă italiană tradițională care se prepară cu dragoste.',
        ingredients: [
          '400g paste',
          '500g carne de vită tocată',
          '2 cepe',
          '2 morcovi',
          '2 tulpini țelină',
          '400g roșii în conserve',
          '100g parmezan',
          'Busuioc proaspăt'
        ],
        instructions: [
          InstructionStep(
            description: 'Tăie ceapa, morcovii și țelina în cuburi mici. Încălzește uleiul într-o cratiță mare.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Călește legumele până devin moi și transparente. Adaugă carnea și prăjește până se rumenește.',
          ),
          InstructionStep(
            description: 'Adaugă roșiile, busuiocul și condimentele. Lasă să fiarbă la foc mic timp de 2 ore.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Fierbe pastele conform instrucțiunilor. Amestecă cu sosul și servește cu parmezan ras.',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 150),
        tags: ['paste', 'italian', 'carne', 'tradițional'],
        creatorId: 'user6',
        creatorName: 'Chef Marco',
        createdAt: DateTime.now(),
        dietaryCriteria: ['Vegetarian', 'Nut Free'],
      ),
      Recipe(
        id: '4',
        title: 'Chocolate Lava Cake',
        imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9',
        description: 'Desert elegant cu centru lichid de ciocolată, perfect pentru ocazii speciale.',
        ingredients: [
          '150g ciocolată neagră',
          '150g unt',
          '3 ouă',
          '75g zahăr',
          '50g făină',
          '1 linguriță esență de vanilie',
          'Puțină sare'
        ],
        instructions: [
          InstructionStep(
            description: 'Încălzește cuptorul la 200°C. Ungi 4 forme pentru muffin cu unt și presară cu cacao.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Topă ciocolata și untul la bain-marie. Amestecă până se combină perfect.',
          ),
          InstructionStep(
            description: 'Bate ouăle cu zahărul până devin spumoase. Încorporează în amestecul de ciocolată.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Adaugă făina și vanilia. Varsă în forme și coace 12-14 minute.',
          ),
          InstructionStep(
            description: 'Servește imediat, cu centrul lichid. Poți adăuga înghețată sau fructe de pădure.',
            mediaUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 25),
        tags: ['desert', 'ciocolată', 'dulce', 'elegant'],
        creatorId: 'user8',
        creatorName: 'Chef Sophie',
        createdAt: DateTime.now(),
        dietaryCriteria: [],
      ),
      Recipe(
        id: '5',
        title: 'Sushi Roll California',
        imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
        description: 'Sushi roll clasic cu crab, avocado și castraveți. Perfect pentru începători în arta sushi-ului.',
        ingredients: [
          '2 căni orez pentru sushi',
          '4 foi nori',
          '200g crab stick',
          '1 avocado',
          '1 castravețe',
          'Wasabi și gari pentru servire'
        ],
        instructions: [
          InstructionStep(
            description: 'Pune o foaie de nori pe bambusul pentru sushi cu partea lucioasă în jos. Umezește-ți mâinile cu apă pentru a evita lipirea orezului.',
            mediaUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
          ),
          InstructionStep(
            description: 'Întinde orezul pe nori, lăsând aproximativ 1 cm liber la partea de sus. Asigură-te că orezul este distribuit uniform.',
          ),
          InstructionStep(
            description: 'Pune ingredientele în centrul orezului: crab stick, avocado și castravețe tăiate în fâșii. Nu pune prea multe ingrediente.',
          ),
          InstructionStep(
            description: 'Ridică marginea de jos a bambusului și începe să rulezi nori-ul, apăsând ușor pentru a forma un cilindru compact.',
          ),
          InstructionStep(
            description: 'Umezește marginea liberă de nori cu apă și termină de rulat. Apasă ușor pentru a sigila roll-ul.',
            mediaUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136',
          ),
          InstructionStep(
            description: 'Cu un cuțit foarte ascuțit, taie roll-ul în 6-8 bucăți. Umezește cuțitul între tăieturi pentru a obține tăieturi curate.',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 30),
        tags: ['sushi', 'japonez', 'pescuit', 'raw'],
        creatorId: 'user5',
        creatorName: 'Chef Yuki',
        createdAt: DateTime.now(),
        dietaryCriteria: [],
      ),
      Recipe(
        id: '6',
        title: 'Beef Stir Fry',
        imageUrl: 'https://images.unsplash.com/photo-1515669097368-22e68427d265',
        description: 'Stir fry rapid cu carne de vită, legume proaspete și sos de soia. Perfect pentru o cină rapidă și sănătoasă.',
        ingredients: [
          '400g carne de vită tăiată în fâșii',
          '2 morcovi',
          '1 broccoli',
          '1 ardei gras',
          '2 căței de usturoi',
          '1 linguriță ghimbir ras',
          '3 linguri sos de soia',
          '1 linguriță ulei de susan'
        ],
        instructions: [
          InstructionStep(
            description: 'Tăie carnea în fâșii subțiri și legumele în bucăți egale. Pregătește sosul de soia.',
            mediaUrl: 'https://images.unsplash.com/photo-1515669097368-22e68427d265',
          ),
          InstructionStep(
            description: 'Încălzește uleiul într-un wok sau cratiță mare. Prăjește carnea până se rumenește.',
          ),
          InstructionStep(
            description: 'Adaugă legumele și prăjește rapid, păstrându-le crocante.',
            mediaUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9',
          ),
          InstructionStep(
            description: 'Adaugă usturoiul, ghimbirul și sosul de soia. Amestecă rapid și servește cu orez.',
          ),
        ],
        totalEstimatedTime: const Duration(minutes: 20),
        tags: ['asian', 'rapid', 'sănătos', 'legume'],
        creatorId: 'user9',
        creatorName: 'Chef Wei',
        createdAt: DateTime.now(),
        dietaryCriteria: [],
      ),
    ];
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
          // Calculate if filters are active
          final hasActiveFilters = selectedDietaryCriteria.isNotEmpty || 
                                 minTime.inMinutes != -1 || 
                                 maxTime.inMinutes != -1;
          
          // Get filtered recipes
          final recipesToShow = hasActiveFilters ? filteredRecipes : recipes;
          
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: recipesToShow.isEmpty && hasActiveFilters
                ? _buildNoResultsView()
                : CardSwiper(
                    scale: 1,
                    numberOfCardsDisplayed: recipesToShow.length == 1 ? 1 : 2,
                    backCardOffset: const Offset(0, 0),
                    controller: controller,
                    isLoop: false, // Allow loop for single card
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
          );
        },
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() {
      currentIndex = currentIndex ?? 0;
    });
    return true;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _buildFilterBottomSheet(),
    ).then((result) {
      // Modal closed - no action needed as filters are applied automatically
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
                      onPressed: () {
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Filters (${filteredRecipes.length} recipes)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
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

  Widget _buildNoResultsView() {
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

