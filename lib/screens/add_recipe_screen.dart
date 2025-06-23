import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forking/models/recipe.dart';

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
  
  // State for complex data
  final List<String> _ingredients = [];
  final List<InstructionStep> _instructions = [];
  final List<TextEditingController> _instructionControllers = [];
  final List<TextEditingController> _timeControllers = [];
  File? _pickedImage;
  
  // TODO: Add controllers for tags and total time

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    // Dispose all dynamic controllers
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    for (var controller in _timeControllers) {
      controller.dispose();
    }
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
    setState(() {
      _instructions.add(InstructionStep(description: ''));
      _instructionControllers.add(TextEditingController());
      _timeControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      // Important: dispose controller-ul înainte de a-l șterge din listă
      _instructionControllers[index].dispose();
      _timeControllers[index].dispose();
      _instructionControllers.removeAt(index);
      _timeControllers.removeAt(index);
      _instructions.removeAt(index);
    });
  }

  void _updateInstructionDescription(int index, String description) {
    setState(() {
      _instructions[index].description = description;
    });
  }

  void _updateInstructionTime(int index, String timeInMinutes) {
    setState(() {
      final minutes = int.tryParse(timeInMinutes);
      if (minutes != null) {
        _instructions[index].estimatedTime = Duration(minutes: minutes);
      } else {
        _instructions[index].estimatedTime = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress image to save space
      maxWidth: 600,     // Resize image to a reasonable width
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickMediaForStep(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        _instructions[index].localMediaFile = File(pickedFile.path);
      });
    }
  }

  void _removeMediaForStep(int index) {
    setState(() {
      _instructions[index].localMediaFile = null;
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
              _buildInstructionsSection(),
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
        onTap: _pickImage,
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
          child: _pickedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11), // one less than container to avoid overflow
                  child: Image.file(
                    _pickedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
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

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_instructions.isEmpty)
          Center(
            child: Text(
              'Add the first step below.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _instructions.length,
            itemBuilder: (context, index) {
              return _buildInstructionStepCard(index);
            },
          ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Step'),
            onPressed: _addInstruction,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStepCard(int index) {
    final step = _instructions[index]; // Get the current step for easier access

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeInstruction(index),
                ),
              ],
            ),
            TextFormField(
              controller: _instructionControllers[index],
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Mix all ingredients...',
              ),
              validator: (value) => value!.isEmpty ? 'Step cannot be empty' : null,
              onChanged: (value) {
                _updateInstructionDescription(index, value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _timeControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Time (min)',
                      hintText: 'e.g., 15',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateInstructionTime(index, value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: step.localMediaFile == null
                      ? OutlinedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Media'),
                          onPressed: () => _pickMediaForStep(index),
                        )
                      : Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                step.localMediaFile!,
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.white70),
                              onPressed: () => _removeMediaForStep(index),
                            )
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}