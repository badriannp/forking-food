import 'package:flutter/material.dart';
import 'package:forking/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final BoxConstraints constraints;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shadowColor: Theme.of(context).colorScheme.onSurface.withAlpha(50),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          spacing: 40,
          children: [
            // Recipe image with header - full card height
            SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: Stack(
                children: [
                  // Recipe image
                  SizedBox(
                    height: constraints.maxHeight,
                    width: constraints.maxWidth,
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 160,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(200),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Recipe info over image
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.white.withAlpha(220),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.creatorName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.white.withAlpha(220),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.totalEstimatedTime.inMinutes} min',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Recipe content below image
            Column(
              spacing: 32,
              children: [
                // Tags
                _buildTags(context),
                
                // Description
                _buildDescription(context),
                
                // Ingredients
                _buildIngredients(context),
                
                // Instructions
                _buildInstructions(context),
                
                // Dietary Criteria
                _buildDietaryCriteria(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 6.0,
        runSpacing: 4.0,
        children: recipe.tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(75),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(175),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '\t${recipe.description}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildIngredients(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recipe.ingredients.map((ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 6,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        // Instructions title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Instructions content
        ...recipe.instructions.asMap().entries.map((entry) {
          return Column(
            spacing: 16,
            children: [
              _buildInstructionItem(context, entry.key + 1, entry.value),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInstructionItem(BuildContext context, int stepNumber, InstructionStep step) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step text with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Step content
              Expanded(
                child: Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Photo if exists
        if (step.mediaUrl != null) ...[
          SizedBox(
            width: double.infinity,
            child: Image.network(
              step.mediaUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDietaryCriteria(BuildContext context) {
    return recipe.dietaryCriteria.isNotEmpty
    ? Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: recipe.dietaryCriteria.map((criteria) => Chip(
            label: Text(
              criteria,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
            shape: StadiumBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          )).toList(),
        ),
      )
    : const SizedBox(height: 16);
  }
} 