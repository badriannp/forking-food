import 'package:flutter/material.dart';
import 'package:forking/screens/tabs/add_recipe_screen.dart' as tab_screen;

class AddRecipeScreen extends StatelessWidget {
  const AddRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return tab_screen.AddRecipeScreen(
      onRecipeAdded: () {
        // Navigate back to the previous screen
        Navigator.pop(context);
      },
    );
  }
}