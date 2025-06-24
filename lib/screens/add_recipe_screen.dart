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
  
  // Tag logic
  final List<String> _allTags = [
    'pasta', 'vegan', 'grill', 'desert', 'rapid', 'mic dejun', 'fără gluten', 'sănătos', 'salată', 'pizza', 'italian', 'carne', 'pește', 'supa', 'gustare', 'copii', 'fără zahăr', 'fără lactoză', 'post', 'tradițional', 'exotic',
  ];
  final List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();
  String _tagInput = '';

  int _totalHours = 0;
  int _totalMinutes = 0;

  // Focus nodes pentru navigare cu tastatura
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _hoursFocus = FocusNode();
  final FocusNode _minutesFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();
  final FocusNode _ingredientFocus = FocusNode();
  final List<FocusNode> _instructionFocuses = [];

  @override
  void initState() {
    super.initState();
    _instructions.add(InstructionStep(description: ''));
    _instructionControllers.add(TextEditingController());
    _instructionFocuses.add(FocusNode());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _tagController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _hoursFocus.dispose();
    _minutesFocus.dispose();
    _tagFocus.dispose();
    _ingredientFocus.dispose();
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    for (var focus in _instructionFocuses) {
      focus.dispose();
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
      _instructionFocuses.add(FocusNode());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      if (_instructions.length == 1) {
        // Dacă e singurul pas, doar golește-l
        _instructionControllers[index].clear();
        _instructions[index].description = '';
        _instructions[index].localMediaFile = null;
        // (opțional) Focus pe el
        FocusScope.of(context).requestFocus(_instructionFocuses[index]);
      } else {
        _instructionControllers[index].dispose();
        _instructionFocuses[index].dispose();
        _instructionControllers.removeAt(index);
        _instructionFocuses.removeAt(index);
        _instructions.removeAt(index);
      }
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

  void _onTagInputChanged(String value) {
    setState(() {
      _tagInput = value;
    });
  }

  List<String> get _filteredTags {
    if (_tagInput.isEmpty) return [];
    return _allTags
        .where((tag) => tag.toLowerCase().contains(_tagInput.toLowerCase()) && !_selectedTags.contains(tag))
        .toList();
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
        _tagInput = '';
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _selectedTags.removeAt(index);
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  focusNode: _titleFocus,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Recipe Title'),
                  validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_descriptionFocus);
                  },
                ),
                const SizedBox(height: 16),

                // 3. Description
                TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_hoursFocus);
                  },
                ),
                const SizedBox(height: 24),

                // Timp total estimat
                _buildTotalTimeSection(),
                const SizedBox(height: 24),

                // 3. Tags section
                _buildTagsSection(),
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
                  focusNode: _ingredientFocus,
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
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (focusNode != null) {
              FocusScope.of(context).requestFocus(focusNode);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: hintText),
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_instructionFocuses.isNotEmpty ? _instructionFocuses[0] : null);
                },
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

  Widget _buildTotalTimeSection() {
    return Row(
      children: [
        Text('Estimated time:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: _totalHours.toString(),
            focusNode: _hoursFocus,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'h'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _totalHours = int.tryParse(value) ?? 0;
              });
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_minutesFocus);
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: _totalMinutes.toString(),
            focusNode: _minutesFocus,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'min'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _totalMinutes = int.tryParse(value) ?? 0;
              });
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_tagFocus);
            },
          ),
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
    final step = _instructions[index];
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
                if (_instructions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeInstruction(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionControllers[index],
              focusNode: _instructionFocuses[index],
              textInputAction: index == 0 && _instructionControllers.length > 1
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Mix all ingredients...',
              ),
              validator: (value) => value!.isEmpty ? 'Step cannot be empty' : null,
              onChanged: (value) {
                _updateInstructionDescription(index, value);
              },
              onFieldSubmitted: (_) {
                if (index + 1 < _instructionFocuses.length) {
                  FocusScope.of(context).requestFocus(_instructionFocuses[index + 1]);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          focusNode: _tagFocus,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Add or search tag',
            prefixIcon: Icon(Icons.tag),
          ),
          onChanged: _onTagInputChanged,
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
              _addTag(tag);
            }
            FocusScope.of(context).requestFocus(_ingredientFocus);
          },
        ),
        if (_tagInput.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._filteredTags.map((tag) => ListTile(
                    title: Text(tag),
                    leading: const Icon(Icons.tag),
                    onTap: () => _addTag(tag),
                  )),
              if (!_allTags.contains(_tagInput) && !_selectedTags.contains(_tagInput))
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text('Add "$_tagInput"'),
                  onTap: () => _addTag(_tagInput),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedTags.asMap().entries.map((entry) {
            final idx = entry.key;
            final tag = entry.value;
            return Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(idx),
            );
          }).toList(),
        ),
      ],
    );
  }
}