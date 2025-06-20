import 'package:flutter/material.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _instructionController = TextEditingController();

  // Lists to hold dynamic data
  final List<String> _ingredients = [];
  final List<String> _instructions = [];

  // TODO: Add state for picked image

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    if (_instructionController.text.trim().isNotEmpty) {
      setState(() {
        _instructions.add(_instructionController.text.trim());
        _instructionController.clear();
      });
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Add a new Recipe',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Picker
              _buildImagePicker(context),
              const SizedBox(height: 24),

              // 2. Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Recipe Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // 3. Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 24),

              // 4. Ingredients
              _buildDynamicSection(
                context: context,
                title: 'Ingredients',
                hintText: 'e.g., 200g flour',
                controller: _ingredientController,
                items: _ingredients,
                onAdd: _addIngredient,
                onRemove: _removeIngredient,
              ),
              const SizedBox(height: 24),

              // 5. Instructions
              _buildDynamicSection(
                context: context,
                title: 'Instructions',
                hintText: 'e.g., Mix all ingredients',
                controller: _instructionController,
                items: _instructions,
                onAdd: _addInstruction,
                onRemove: _removeInstruction,
              ),
              const SizedBox(height: 32),

              // 6. Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Process data
                    }
                  },
                  child: const Text('Publish Recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: Implement image picking logic
        },
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to add a photo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicSection({
    required BuildContext context,
    required String title,
    required String hintText,
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.12)),
            color: items.isEmpty
                ? Colors.transparent
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: items.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                    'No ${title.toLowerCase()} added yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: items.asMap().entries.map((entry) {
                    int index = entry.key;
                    String item = entry.value;
                    return Chip(
                      label: Text(item),
                      onDeleted: () => onRemove(index),
                      deleteIconColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(hintText: hintText),
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
              color: Theme.of(context).colorScheme.primary,
              iconSize: 30,
            ),
          ],
        ),
      ],
    );
  }
} 