import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forking/models/recipe.dart';
import 'package:forking/services/recipe_service.dart';
import 'package:flutter/services.dart';
import 'package:forking/services/auth_service.dart';
import 'package:image_cropper/image_cropper.dart';

class AddRecipeScreen extends StatefulWidget {
  final VoidCallback? onRecipeAdded;
  const AddRecipeScreen({Key? key, this.onRecipeAdded}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();

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
  List<String> _localTags = []; // All tags from Firebase + newly added
  final List<String> _selectedTags = []; // Selected tags for recipe
  final TextEditingController _tagController = TextEditingController();
  String _tagInput = '';
  bool _isLoadingTags = false;

  // Dietary criteria logic
  List<String> _localDietary = []; // All dietary criteria from Firebase + newly added
  final List<String> _selectedDietary = []; // Selected dietary criteria for recipe
  final TextEditingController _dietaryController = TextEditingController();
  String _dietaryInput = '';
  bool _isLoadingDietaryCriteria = false;

  int _totalHours = 0;
  int _totalMinutes = 0;

  // Focus nodes pentru navigare cu tastatura
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();
  final FocusNode _ingredientFocus = FocusNode();
  final FocusNode _dietaryFocus = FocusNode();
  final List<FocusNode> _instructionFocuses = [];

  // Validation state
  bool _showImageError = false;
  bool _showTimeError = false;
  bool _showIngredientsError = false;
  bool _showTitleError = false;
  bool _showDescriptionError = false;
  List<bool> _showInstructionErrors = [];
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _instructions.add(InstructionStep(description: ''));
    _instructionControllers.add(TextEditingController());
    _instructionFocuses.add(FocusNode());
    _showInstructionErrors.add(false);
    
    // Load tags and dietary criteria from database
    _loadTags();
    _loadDietaryCriteria();
  }

  /// Load all available tags from database
  Future<void> _loadTags() async {
    setState(() {
      _isLoadingTags = true;
    });
    
    try {
      final tags = await _recipeService.getAllTags();
      setState(() {
        _localTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  /// Add a new tag to local list and selected list
  Future<void> _addNewTag(String tag) async {
    if (tag.trim().isEmpty) return;
    
    final cleanTag = tag.trim();
    if (_selectedTags.contains(cleanTag)) return;
    
    try {
      setState(() {
        _selectedTags.add(cleanTag);
        if (!_localTags.contains(cleanTag)) {
          _localTags.add(cleanTag);
        }
        _tagController.clear();
        _tagInput = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add tag: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Load all available dietary criteria from database
  Future<void> _loadDietaryCriteria() async {
    setState(() {
      _isLoadingDietaryCriteria = true;
    });
    
    try {
      final criteria = await _recipeService.getAllDietaryCriteria();
      setState(() {
        _localDietary = criteria;
        _isLoadingDietaryCriteria = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDietaryCriteria = false;
      });
    }
  }

  /// Add a new dietary criteria to local list and selected list
  Future<void> _addNewDietaryCriteria(String criteria) async {
    if (criteria.trim().isEmpty) return;
    
    final cleanCriteria = _normalizeDietaryCriteria(criteria.trim());
    if (_selectedDietary.contains(cleanCriteria)) return;
    
    try {
      setState(() {
        _selectedDietary.add(cleanCriteria);
        if (!_localDietary.contains(cleanCriteria)) {
          _localDietary.add(cleanCriteria);
        }
        _dietaryController.clear();
        _dietaryInput = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add dietary criteria: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Normalize dietary criteria to Title Case
  String _normalizeDietaryCriteria(String criteria) {
    if (criteria.isEmpty) return criteria;
    
    // Convert to Title Case (first letter of each word uppercase)
    return criteria.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _tagController.dispose();
    _dietaryController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _tagFocus.dispose();
    _ingredientFocus.dispose();
    _dietaryFocus.dispose();
    _scrollController.dispose();
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
      // Crop image to 4:3 aspect ratio
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Recipe Photo',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Recipe Photo',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
          ),
        ],
      );
      if (croppedFile != null) {
      setState(() {
          _pickedImage = File(croppedFile.path);
          _showImageError = false;
      });
      }
    }
  }

  Future<void> _pickMediaForStep(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
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
  // (Old functions removed - using new database-based system)

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
        _instructionControllers[index].clear();
        _instructions[index].description = '';
        _instructions[index].localMediaFile = null;
        _showInstructionErrors[index] = false;
        // (optional) Focus on the instruction
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToInvalidField();
      return;
    }

    if (_pickedImage == null) {
      setState(() => _showImageError = true);
      _scrollToInvalidField();
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() => _showTitleError = true);
      _scrollToInvalidField();
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _showDescriptionError = true);
      _scrollToInvalidField();
      return;
    }

    if (_totalHours == 0 && _totalMinutes == 0) {
      setState(() => _showTimeError = true);
      _scrollToInvalidField();
      return;
    }

    // Tags are now optional - removed validation
    // if (_selectedTags.isEmpty) {
    //   setState(() => _showTagsError = true);
    //   _scrollToInvalidField();
    //   return;
    // }

    if (_ingredients.isEmpty) {
      setState(() => _showIngredientsError = true);
      _scrollToInvalidField();
      return;
    }

    // Validate instructions - at least one step with description
    final validInstructions = _instructions.where((i) => i.description.trim().isNotEmpty).toList();
    if (validInstructions.isEmpty) {
      setState(() {
        _showInstructionErrors.fillRange(0, _showInstructionErrors.length, true);
      });
      _scrollToInvalidField();
      return;
    }

    // Check for steps with images but no description
    for (int i = 0; i < _instructions.length; i++) {
      final step = _instructions[i];
      if ((step.mediaUrl != null && step.mediaUrl!.isNotEmpty) || 
          (step.localMediaFile != null) && step.description.trim().isEmpty) {
        setState(() {
          _showInstructionErrors[i] = true;
        });
        _scrollToInvalidField();
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final String? userId = _authService.userId;
      final String? displayName = _authService.userDisplayName;
      final String? photoURL = _authService.userPhotoURL;
      
      if (userId == null || displayName == null) {
        throw Exception('User not authenticated');
      }

      // Upload new tags to database first
      final existingTags = await _recipeService.getAllTags();
      for (String tag in _selectedTags) {
        if (!existingTags.contains(tag)) {
          try {
            await _recipeService.addTag(tag);
          } catch (e) {
            // Continue with recipe upload even if tag upload fails
          }
        }
      }

      // Upload new dietary criteria to database first
      final existingCriteria = await _recipeService.getAllDietaryCriteria();
      for (String criteria in _selectedDietary) {
        if (!existingCriteria.contains(criteria)) {
          try {
            await _recipeService.addDietaryCriteria(criteria);
          } catch (e) {
            // Continue with recipe upload even if dietary criteria upload fails
          }
        }
      }

      final recipe = Recipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        imageUrl: _pickedImage!.path,
        description: _descriptionController.text.trim(),
        ingredients: List.from(_ingredients),
        instructions: _instructions.where((i) => i.description.trim().isNotEmpty).toList(),
        totalEstimatedTime: Duration(hours: _totalHours, minutes: _totalMinutes),
        tags: List.from(_selectedTags),
        creatorId: userId,
        creatorName: displayName,
        creatorPhotoURL: photoURL,
        createdAt: DateTime.now(),
        dietaryCriteria: _selectedDietary.toList(),
      );

      await _recipeService.saveRecipe(recipe);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved successfully!')),
        );
        
        // Reset form
        resetForm();
        
        // Callback to navigate to profile
        widget.onRecipeAdded?.call();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _ingredientController.clear();
      _tagController.clear();
      _dietaryController.clear();
      _pickedImage = null;
      _totalHours = 0;
      _totalMinutes = 0;
      _selectedTags.clear();
      _ingredients.clear();
      _instructions.clear();
      _instructionControllers.forEach((c) => c.dispose());
      _instructionControllers.clear();
      _instructionFocuses.forEach((f) => f.dispose());
      _instructionFocuses.clear();
      _showInstructionErrors.clear();
      _selectedDietary.clear();
      _showImageError = false;
      _showTimeError = false;
      _showIngredientsError = false;
      _showTitleError = false;
      _showDescriptionError = false;
      _tagInput = '';
      _dietaryInput = '';
      _instructions.add(InstructionStep(description: ''));
      _instructionControllers.add(TextEditingController());
      _instructionFocuses.add(FocusNode());
      _showInstructionErrors.add(false);
    });
  }

  Future<bool> _showConfirmDialog(String content, String confirmText) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(confirmText),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  bool get _hasRecipeDataToClear {
    return _titleController.text.isNotEmpty ||
      _descriptionController.text.isNotEmpty ||
      _ingredientController.text.isNotEmpty ||
      _tagController.text.isNotEmpty ||
      _dietaryController.text.isNotEmpty ||
      _pickedImage != null ||
      _totalHours > 0 ||
      _totalMinutes > 0 ||
      _selectedTags.isNotEmpty ||
      _ingredients.isNotEmpty ||
      _instructions.length > 1 ||
      _instructions.first.description.isNotEmpty ||
      _selectedDietary.isNotEmpty;
  }

  void _onClearPressed() async {
    if (!_hasRecipeDataToClear) return;
    final confirmed = await _showConfirmDialog(
      'Clear recipe?',
      'Clear',
    );
    if (confirmed) {
      resetForm();
    }
  }

  /// Scroll to the first invalid field
  void _scrollToInvalidField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showTitleError) {
        _scrollToWidget(_titleFocus);
      } else if (_showDescriptionError) {
        _scrollToWidget(_descriptionFocus);
      } else if (_showImageError) {
        // Scroll to image section
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (_showTimeError) {
        // Scroll to time section
        _scrollController.animateTo(
          200,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (_showIngredientsError) {
        _scrollToWidget(_ingredientFocus);
      } else if (_showInstructionErrors.any((error) => error)) {
        // Find the first step with error and scroll to it
        final errorIndex = _showInstructionErrors.indexWhere((error) => error);
        if (errorIndex >= 0 && errorIndex < _instructionFocuses.length) {
          _scrollToWidget(_instructionFocuses[errorIndex]);
        } else {
          // Fallback to instructions section
          _scrollController.animateTo(
            400,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  /// Scroll to a specific widget
  void _scrollToWidget(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = focusNode.context?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final offset = position.dy - 100; // Offset for better visibility
        _scrollController.animateTo(
          _scrollController.offset + offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasRecipeDataToClear,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasRecipeDataToClear) {
                final shouldPop = await _showConfirmDialog(
                  'Discard changes?',
                  'Discard',
                );
                if (shouldPop && mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
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
                Icons.delete_outline,
                color: _hasRecipeDataToClear
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              tooltip: 'Clear Recipe',
              onPressed: _hasRecipeDataToClear ? _onClearPressed : null,
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            // Close keyboard when tapping outside input fields
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  controller: _scrollController,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      spacing: 40,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Image Picker
                        _buildImagePicker(context),

                        // 2. Title
                        TextFormField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Recipe Title',
                            hintText: 'Enter your recipe title',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                            ),
                            errorText: _showTitleError ? 'Please enter a title' : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
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

                        // 3. Description
                        TextFormField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe your recipe...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                            ),
                            errorText: _showDescriptionError ? 'Please enter a description' : null,
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {});
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

                        // Timp total estimat
                        _buildTotalTimeSection(),

                        // 3. Tags section
                        _buildTagsSection(),

                        // 4. Ingredients
                        _buildIngredientsSection(),

                        // 5. Instructions
                        _buildInstructionsSection(),

                        // 6. Dietary Criteria
                        _buildDietaryCriteriaSection(),

                        // Extra space at bottom to ensure content is not hidden behind sticky button
                        // SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                      ],
                    ),
                  ),
                ),
              ),
              // Sticky publish button at bottom
              Container(
                width: double.infinity,
                // padding: const EdgeInsets.all(20.0),
                padding: EdgeInsets.fromLTRB(
                  20.0, 
                  12.0, 
                  20.0, 
                  24.0 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  // border: Border(
                  //   top: BorderSide(
                  //     color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  //     width: 1,
                  //   ),
                  // ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Publishing...'),
                        ],
                      )
                    : const Text('Publish Recipe'),
                ),
              ),
            ],
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
                : Column(
                    children: _ingredients.asMap().entries.map((entry) {
                      int index = entry.key;
                      String item = entry.value;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                    size: 20,
                                  ),
                                  onPressed: () => _removeIngredient(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          if (index < _ingredients.length - 1)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              indent: 36,
                            ),
                        ],
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
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  labelText: 'Ingredient',
                  hintText: 'e.g., 200g flour',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...List.generate(_instructions.length, (index) {
          return _buildInstructionStepCard(index);
        }),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add step'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: Theme.of(context).colorScheme.onSurface
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline, 
                    color: _instructions.length > 1 
                        ? Colors.red 
                        : Colors.grey.withOpacity(0.3),
                  ),
                  onPressed: _instructions.length > 1 
                      ? () => _removeInstruction(index)
                      : null,
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
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                ),
                errorText: _showInstructionErrors[index] 
                    ? (step.localMediaFile != null || (step.mediaUrl != null && step.mediaUrl!.isNotEmpty))
                        ? 'Step with image must have a description'
                        : 'Step cannot be empty'
                    : null,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _tagController,
          focusNode: _tagFocus,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            labelText: 'Add or search tag',
            hintText: 'Search or add a new tag',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
            ),
            prefixIcon: _isLoadingTags 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tag),
          ),
          onChanged: (value) {
            setState(() {
              _tagInput = value;
            });
          },
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
              if (!_localTags.contains(tag)) {
                _addNewTag(tag);
              } else {
                // Select existing tag
                setState(() {
                  _selectedTags.add(tag);
                  _tagController.clear();
                  _tagInput = '';
                });
              }
            }
          },
        ),
        if (_tagInput.isNotEmpty && _localTags.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
            children: [
                if (!_localTags.contains(_tagInput.trim()) && _tagInput.trim().isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.add, size: 20),
                  title: Text('Add "${_tagInput.trim()}"'),
                    onTap: () => _addNewTag(_tagInput.trim()),
                ),
                ..._localTags
                    .where((tag) => tag.toLowerCase().contains(_tagInput.trim().toLowerCase()))
                    .take(5)
                    .map((tag) => ListTile(
                    title: Text(tag),
                          leading: const Icon(Icons.tag, size: 20),
                          onTap: () {
                            if (!_selectedTags.contains(tag)) {
                              setState(() {
                                _selectedTags.add(tag);
                                _tagController.clear();
                                _tagInput = '';
                              });
                              // Tags are optional - no error state to clear
                            }
                          },
                  )),
            ],
          ),
          ),
        // Show "Add new" even if no tags found
        if (_tagInput.trim().isNotEmpty && _localTags.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.add, size: 20),
              title: Text('Add "${_tagInput.trim()}"'),
              onTap: () => _addNewTag(_tagInput.trim()),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedTags.asMap().entries.map((entry) {
            final idx = entry.key;
            final tag = entry.value;
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _selectedTags.removeAt(idx);
                });
              },
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
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dietary Criteria', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _dietaryController,
            focusNode: _dietaryFocus,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              labelText: 'Add or search criteria',
              hintText: 'e.g., Vegan, Gluten Free...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
              ),
              prefixIcon: _isLoadingDietaryCriteria 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant),
            ),
            onChanged: (value) {
              setState(() {
                _dietaryInput = value;
              });
            },
            onSubmitted: (value) {
              final criteria = value.trim();
              if (criteria.isNotEmpty) {
                final normalizedCriteria = _normalizeDietaryCriteria(criteria);
                if (!_selectedDietary.contains(normalizedCriteria)) {
                  if (!_localDietary.contains(normalizedCriteria)) {
                    // Add new criteria
                    _addNewDietaryCriteria(criteria);
                  } else {
                    // Select existing criteria
                    setState(() {
                      _selectedDietary.add(normalizedCriteria);
                      _dietaryController.clear();
                      _dietaryInput = '';
                    });
                  }
                }
              }
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Show filtered criteria based on search
              ..._localDietary
                  .where((criteria) => _dietaryInput.trim().isEmpty || 
                      criteria.toLowerCase().contains(_dietaryInput.trim().toLowerCase()))
                  .map((criteria) {
                final selected = _selectedDietary.contains(criteria);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedDietary.remove(criteria);
                      } else {
                        _selectedDietary.add(criteria);
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
              // Add new criteria chip if input is not empty and not already in list
              if (_dietaryInput.trim().isNotEmpty && 
                  !_localDietary.any((criteria) => 
                      criteria.toLowerCase() == _dietaryInput.trim().toLowerCase()) &&
                  !_selectedDietary.any((criteria) => 
                      criteria.toLowerCase() == _dietaryInput.trim().toLowerCase()))
                GestureDetector(
                  onTap: () => _addNewDietaryCriteria(_dietaryInput.trim()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _normalizeDietaryCriteria(_dietaryInput.trim()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}