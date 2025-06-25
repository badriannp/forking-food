import 'package:flutter/material.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/screens/recipe_view_screen.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  List<Recipe> get _myRecipes => [
    Recipe(
      id: 'profile_1',
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
          mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
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
      creatorId: 'current_user',
      creatorName: 'Bleo Jua',
      createdAt: DateTime.now(),
      dietaryCriteria: ['Vegetarian', 'Gluten Free'],
    ),
    Recipe(
      id: 'profile_2',
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
          mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
        ),
        InstructionStep(
          description: 'Cu un cuțit foarte ascuțit, taie roll-ul în 6-8 bucăți. Umezește cuțitul între tăieturi pentru a obține tăieturi curate.',
        ),
      ],
      totalEstimatedTime: const Duration(minutes: 30),
      tags: ['sushi', 'japonez', 'pescuit', 'raw'],
      creatorId: 'current_user',
      creatorName: 'Bleo Jua',
      createdAt: DateTime.now(),
      dietaryCriteria: [],
    ),
    Recipe(
      id: 'profile_3',
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
          mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
        ),
        InstructionStep(
          description: 'Fierbe pastele conform instrucțiunilor. Amestecă cu sosul și servește cu parmezan ras.',
        ),
      ],
      totalEstimatedTime: const Duration(minutes: 150),
      tags: ['paste', 'italian', 'carne', 'tradițional'],
      creatorId: 'current_user',
      creatorName: 'Bleo Jua',
      createdAt: DateTime.now(),
      dietaryCriteria: ['Vegetarian', 'Nut Free'],
    ),
    Recipe(
      id: 'profile_4',
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
          mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
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
      tags: ['desert', 'ciocolată', 'elegant', 'rapid'],
      creatorId: 'current_user',
      creatorName: 'Bleo Jua',
      createdAt: DateTime.now(),
      dietaryCriteria: [],
    ),
  ];

  List<Recipe> get _savedRecipes => [
    Recipe(
      id: 'saved_1',
      title: 'Beef Stir Fry',
      imageUrl: 'https://images.unsplash.com/photo-1515669097368-22e68427d265',
      description: 'Prăjitură rapidă de carne de vită cu legume, în stil asiatic. O rețetă sănătoasă și rapidă.',
      ingredients: [
        '400g carne de vită',
        '2 morcovi',
        '1 ardei gras',
        '1 ceapă',
        '2 căței de usturoi',
        '1 linguriță ghimbir',
        '3 linguri sos de soia',
        '2 linguri ulei de susan'
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
    Recipe(
      id: 'saved_2',
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
          mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
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
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildProfileHeader(context)),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            children: [
              // Grid for "My Recipes"
              _buildRecipesGrid(),
              // Grid for "Saved" recipes
              _buildRecipesGrid(isSaved: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1554151228-14d9def656e4'), // Dummy image
          ),
          const SizedBox(height: 16),
          Text(
            'Bleo Jua', // Dummy name
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '@bleojua', // Dummy username
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(context, Icons.favorite_border, '1.2k'),
              _buildStatColumn(context, Icons.receipt_long, '12'),
              _buildStatColumn(context, Icons.star_border, '89'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 24),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        )),
      ],
    );
  }

  Widget _buildRecipesGrid({bool isSaved = false}) {
    // Folosește rețetele reale
    final recipes = isSaved ? _savedRecipes : _myRecipes;

    return GridView.builder(
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
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Titlu rețetă
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecipeCardOverlay(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(150),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on the card
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
                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
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
              ],
            ),
          ),
        );
      },
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