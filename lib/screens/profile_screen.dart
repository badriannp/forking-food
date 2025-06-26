import 'package:flutter/material.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/widgets/recipe_card.dart';
import 'package:flutter/services.dart';
import 'package:forking/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:forking/screens/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with current user's display name or empty string
    final currentName = _authService.userDisplayName;
    _nameController.text = currentName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 300,
    );

    if (pickedFile != null) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading profile photo...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        // Upload image to Firebase Storage and update profile
        await _authService.updateProfileImage(File(pickedFile.path));
        
        // Refresh the UI
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isNotEmpty) {
      try {
        await _authService.updateDisplayName(_nameController.text.trim());
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update name. Please try again.')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

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
      creatorName: 'Chef Elena',
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
      creatorName: 'Chef Yuki',
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
      creatorName: 'Chef Marco',
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
      creatorName: 'Chef Sophie',
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
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _signOut,
            ),
          ],
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
    final userDisplayName = _authService.userDisplayName ?? 'User';
    final userPhotoURL = _authService.userPhotoURL;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo with edit button
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: userPhotoURL != null 
                    ? NetworkImage(userPhotoURL)
                    : null,
                child: userPhotoURL == null 
                    ? Icon(
                        Icons.person,
                        size: 44,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name with edit functionality
                if (_isEditingName) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveName,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = userDisplayName;
                          });
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userDisplayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          setState(() {
                            _isEditingName = true;
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _nameFocus.requestFocus();
                          });
                        },
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatFlex(context, Icons.favorite_border, '1.2k'),
                    _buildStatFlex(context, Icons.receipt_long, '12'),
                    _buildStatFlex(context, Icons.star_border, '89'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatFlex(BuildContext context, IconData icon, String value) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.82);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid({bool isSaved = false}) {
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
                // Titlu
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