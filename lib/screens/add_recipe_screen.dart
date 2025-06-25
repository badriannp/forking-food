import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forking/models/recipe.dart';
import 'package:flutter/services.dart';

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
  File? _pickedImage;
  
  // Tag logic
  final List<String> _allTags = [
    'pasta', 'vegan', 'grill', 'desert', 'rapid', 'mic dejun'];
  final List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();
  String _tagInput = '';

  int _totalHours = 0;
  int _totalMinutes = 0;

  // Focus nodes pentru navigare cu tastatura
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();
  final FocusNode _ingredientFocus = FocusNode();
  final List<FocusNode> _instructionFocuses = [];

  // Validation state
  bool _showImageError = false;
  bool _showTimeError = false;
  bool _showTagsError = false;
  bool _showIngredientsError = false;
  bool _showTitleError = false;
  bool _showDescriptionError = false;
  List<bool> _showInstructionErrors = [];

  final List<String> dietaryCriteriaList = [
    'Vegan',
    'Vegetarian',
    'Lactose Free',
    'Gluten Free',
    'Nut Free',
    'Dairy Free',
    'Egg Free',
    'Sugar Free',
    'Low Carb',
    'Low Fat',
    'Paleo',
    'Keto',
    'Halal',
    'Kosher',
  ];
  List<String> _selectedCriteria = [];

  @override
  void initState() {
    super.initState();
    _instructions.add(InstructionStep(description: ''));
    _instructionControllers.add(TextEditingController());
    _instructionFocuses.add(FocusNode());
    _showInstructionErrors.add(false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _tagController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
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

  // ===== IMAGE HANDLING =====
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
        _showImageError = false; // Clear error when image is selected
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

  // ===== TIME HANDLING =====
  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(initialItem: _totalHours),
                  onSelectedItemChanged: (value) {
                    setState(() {
                      _totalHours = value;
                      if (_totalHours > 0 || _totalMinutes > 0) {
                        _showTimeError = false; // Clear error when time is selected
                      }
                    });
                  },
                  children: List.generate(25, (i) => Center(child: Text('$i h'))),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(initialItem: _totalMinutes),
                  onSelectedItemChanged: (value) {
                    setState(() {
                      _totalMinutes = value;
                      if (_totalHours > 0 || _totalMinutes > 0) {
                        _showTimeError = false; // Clear error when time is selected
                      }
                    });
                  },
                  children: List.generate(60, (i) => Center(child: Text('$i min'))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== TAG MANAGEMENT =====
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
        _showTagsError = false; // Clear error when tag is added
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _selectedTags.removeAt(index);
      // Don't clear error here as we want to show error if list becomes empty
    });
  }

  // ===== INGREDIENTS MANAGEMENT =====
  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
        _showIngredientsError = false; // Clear error when ingredient is added
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      // Don't clear error here as we want to show error if list becomes empty
    });
  }

  // ===== INSTRUCTIONS MANAGEMENT =====
  void _addInstruction() {
    setState(() {
      _instructions.add(InstructionStep(description: ''));
      _instructionControllers.add(TextEditingController());
      _instructionFocuses.add(FocusNode());
      _showInstructionErrors.add(false);
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      if (_instructions.length == 1) {
        // Dacă e singurul pas, doar golește-l
        _instructionControllers[index].clear();
        _instructions[index].description = '';
        _instructions[index].localMediaFile = null;
        _showInstructionErrors[index] = false;
        // (opțional) Focus pe el
        FocusScope.of(context).requestFocus(_instructionFocuses[index]);
      } else {
        _instructionControllers[index].dispose();
        _instructionFocuses[index].dispose();
        _instructionControllers.removeAt(index);
        _instructionFocuses.removeAt(index);
        _instructions.removeAt(index);
        _showInstructionErrors.removeAt(index);
      }
    });
  }

  void _updateInstructionDescription(int index, String description) {
    setState(() {
      _instructions[index].description = description;
    });
  }

  // ===== VALIDATION =====
  bool _validateField(String value, bool Function() setError) {
    if (value.trim().isEmpty) {
      setState(() => setError());
      return true; // has error
    }
    return false; // no error
  }

  void _onPublish() {
    bool hasErrors = false;

    // Validate title
    if (_validateField(_titleController.text, () => _showTitleError = true)) {
      hasErrors = true;
    }

    // Validate description
    if (_validateField(_descriptionController.text, () => _showDescriptionError = true)) {
      hasErrors = true;
    }

    // Validate image
    if (_pickedImage == null) {
      setState(() => _showImageError = true);
      hasErrors = true;
    }

    // Validate time
    if (_totalHours == 0 && _totalMinutes == 0) {
      setState(() => _showTimeError = true);
      hasErrors = true;
    }

    // Validate tags
    if (_selectedTags.isEmpty) {
      setState(() => _showTagsError = true);
      hasErrors = true;
    }

    // Validate ingredients
    if (_ingredients.isEmpty) {
      setState(() => _showIngredientsError = true);
      hasErrors = true;
    }

    // Validate instruction steps
    for (int i = 0; i < _instructions.length; i++) {
      if (_instructions[i].description.trim().isEmpty) {
        setState(() => _showInstructionErrors[i] = true);
        hasErrors = true;
      }
    }

    if (hasErrors) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe is valid! (Demo)')),
    );
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
                  decoration: InputDecoration(
                    labelText: 'Recipe Title',
                    errorText: _showTitleError ? 'Please enter a title' : null,
                  ),
                  onChanged: (value) {
                    if (_showTitleError && value.trim().isNotEmpty) {
                      setState(() => _showTitleError = false);
                    }
                  },
                  onFieldSubmitted: (_) {
                    if (mounted && _descriptionFocus.canRequestFocus) {
                      FocusScope.of(context).requestFocus(_descriptionFocus);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 3. Description
                TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    errorText: _showDescriptionError ? 'Please enter a description' : null,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    if (_showDescriptionError && value.trim().isNotEmpty) {
                      setState(() => _showDescriptionError = false);
                    }
                  },
                  onFieldSubmitted: (_) {
                    if (mounted && _tagFocus.canRequestFocus) {
                      FocusScope.of(context).requestFocus(_tagFocus);
                    }
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
                _buildIngredientsSection(),
                const SizedBox(height: 24),

                // 5. Instructions
                _buildInstructionsSection(),
                const SizedBox(height: 24),

                // 6. Dietary Criteria
                _buildDietaryCriteriaSection(),
                const SizedBox(height: 24),

                // 7. Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _onPublish,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showImageError 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  width: _showImageError ? 2 : 1,
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
        ),
        if (_showImageError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select a main image for your recipe.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (mounted && _ingredientFocus.canRequestFocus) {
              FocusScope.of(context).requestFocus(_ingredientFocus);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (mounted && _showIngredientsError)
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                width: (mounted && _showIngredientsError) ? 2 : 1,
              ),
              color: _ingredients.isEmpty
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: _ingredients.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No ingredients added yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _ingredients.asMap().entries.map((entry) {
                      int index = entry.key;
                      String item = entry.value;
                      return Chip(
                        label: Text(item),
                        onDeleted: () => _removeIngredient(index),
                        deleteIconColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      );
                    }).toList(),
                  ),
          ),
        ),
        if (mounted && _showIngredientsError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please add at least one ingredient.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ingredientController,
                focusNode: _ingredientFocus,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(hintText: 'e.g., 200g flour'),
                onFieldSubmitted: (_) {
                  _addIngredient();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addIngredient,
              color: Theme.of(context).colorScheme.primary,
              iconSize: 30,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Estimated time:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _showTimePicker,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _showTimeError 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                  width: _showTimeError ? 2 : 1,
                ),
              ),
              child: Text(
                '${_totalHours}h ${_totalMinutes}min',
                style: TextStyle(
                  fontSize: 16,
                  color: _showTimeError 
                    ? Theme.of(context).colorScheme.error
                    : null,
                ),
              ),
            ),
          ],
        ),
        if (_showTimeError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select an estimated time.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
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
              textInputAction: index + 1 < _instructionControllers.length
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Mix all ingredients...',
                errorText: _showInstructionErrors[index] ? 'Step cannot be empty' : null,
              ),
              onChanged: (value) {
                _updateInstructionDescription(index, value);
                if (_showInstructionErrors[index] && value.trim().isNotEmpty) {
                  setState(() => _showInstructionErrors[index] = false);
                }
              },
              onFieldSubmitted: (_) {
                if (index + 1 < _instructionFocuses.length && mounted && _instructionFocuses[index + 1].canRequestFocus) {
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
                          label: const Text('Add Photo'),
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
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleLarge),
        TextField(
          controller: _tagController,
          focusNode: _tagFocus,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Add or search tag',
            prefixIcon: const Icon(Icons.tag),
            errorText: _showTagsError ? 'Please add at least one tag.' : null,
          ),
          onChanged: _onTagInputChanged,
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
              _addTag(tag);
            }
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

  Widget _buildDietaryCriteriaSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dietary Criteria', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: dietaryCriteriaList.map((criteria) {
              final selected = _selectedCriteria.contains(criteria);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCriteria.remove(criteria);
                    } else {
                      _selectedCriteria.add(criteria);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    criteria,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}