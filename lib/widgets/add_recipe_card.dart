import 'package:flutter/material.dart';
import 'package:forking/screens/add_recipe_screen.dart';

class AddRecipeCard extends StatefulWidget {
  final BuildContext context;
  final Function() onRecipeAdded;

  const AddRecipeCard({super.key, required this.context, required this.onRecipeAdded});

  @override
  State<AddRecipeCard> createState() => _AddRecipeCardState();
}

class _AddRecipeCardState extends State<AddRecipeCard> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          widget.context,
          MaterialPageRoute(
            builder: (context) => AddRecipeScreen(
              onRecipeAdded: () {
                widget.onRecipeAdded();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.grey[50],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Recipe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}