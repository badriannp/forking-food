import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/utils/image_utils.dart';
import 'package:forking/widgets/creator_avatar.dart';
import 'package:forking/widgets/add_recipe_card.dart';

class RecipesGrid extends StatefulWidget {
  final bool isSaved;
  final List<Recipe> recipes;
  final bool isLoading;
  final BuildContext context;
  final Function() onRecipeAdded;
  final Function(Recipe) onRecipeTapped;
  final Function(Duration) formatDuration;

  const RecipesGrid({super.key, required this.isSaved, required this.recipes, required this.isLoading, required this.context, required this.onRecipeAdded, required this.onRecipeTapped, required this.formatDuration});

  @override
  State<RecipesGrid> createState() => _RecipesGridState();
}

class _RecipesGridState extends State<RecipesGrid> {

  @override
  Widget build(BuildContext context) {
    final recipes = widget.isSaved ? widget.recipes : widget.recipes;
    final isLoading = widget.isLoading;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (recipes.isEmpty && !isLoading && widget.isSaved) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fork-in recipes to save them\nin your collection!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: widget.isSaved ? recipes.length : recipes.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        // Show add button as first item for My Recipes
        if (!widget.isSaved && index == 0) {
          return AddRecipeCard(context: widget.context, onRecipeAdded: widget.onRecipeAdded);
        }
        
        // Adjust index for recipes (skip add button)
        final recipeIndex = widget.isSaved ? index : index - 1;
        final recipe = recipes[recipeIndex];
        
        return GestureDetector(
          onTap: () {
            widget.onRecipeTapped(recipe);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  fadeInDuration: Duration.zero,
                  imageUrl: getResizedImageUrl(originalUrl: recipe.imageUrl, size: 600),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      imageUrl: recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
                // Gradient peste imagine pentru text
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(179),
                      ],
                    ),
                  ),
                ),
                // Fork-in count in top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.forkInCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Time in top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.formatDuration(recipe.totalEstimatedTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Title and chef name in left bottom
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.isSaved) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Chef avatar
                            CreatorAvatar(
                              imageUrl: recipe.creatorPhotoURL,
                              size: 16,
                              borderColor: Colors.white,
                              fallbackColor: Colors.white.withAlpha(75),
                            ),
                            const SizedBox(width: 4),
                            // Chef name
                            Expanded(
                              child: Text(
                                recipe.creatorName ?? 'Unknown Chef',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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