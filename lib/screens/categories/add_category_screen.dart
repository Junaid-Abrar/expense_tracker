import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/translation_helper.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AddCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  IconData? _selectedIcon;
  Color _selectedColor = AppColors.primary;
  bool _isLoading = false;

  // Predefined icons for categories
  final List<Map<String, dynamic>> _categoryIcons = [
    {'icon': Icons.fastfood.codePoint, 'name': 'Food & Dining'},
    {'icon': Icons.local_gas_station.codePoint, 'name': 'Transportation'},
    {'icon': Icons.shopping_cart.codePoint, 'name': 'Shopping'},
    {'icon': Icons.home.codePoint, 'name': 'Home'},
    {'icon': Icons.medical_services.codePoint, 'name': 'Healthcare'},
    {'icon': Icons.school.codePoint, 'name': 'Education'},
    {'icon': Icons.sports_esports.codePoint, 'name': 'Entertainment'},
    {'icon': Icons.fitness_center.codePoint, 'name': 'Fitness'},
    {'icon': Icons.pets.codePoint, 'name': 'Pets'},
    {'icon': Icons.card_giftcard.codePoint, 'name': 'Gifts'},
    {'icon': Icons.flight.codePoint, 'name': 'Travel'},
    {'icon': Icons.phone.codePoint, 'name': 'Phone & Internet'},
    {'icon': Icons.electric_bolt.codePoint, 'name': 'Utilities'},
    {'icon': Icons.local_laundry_service.codePoint, 'name': 'Personal Care'},
    {'icon': Icons.build.codePoint, 'name': 'Maintenance'},
    {'icon': Icons.account_balance.codePoint, 'name': 'Banking'},
    {'icon': Icons.business.codePoint, 'name': 'Business'},
    {'icon': Icons.casino.codePoint, 'name': 'Recreation'},
    {'icon': Icons.local_cafe.codePoint, 'name': 'Coffee & Drinks'},
    {'icon': Icons.book.codePoint, 'name': 'Books'},
    {'icon': Icons.music_note.codePoint, 'name': 'Music'},
    {'icon': Icons.movie.codePoint, 'name': 'Movies'},
    {'icon': Icons.computer.codePoint, 'name': 'Technology'},
    {'icon': Icons.category.codePoint, 'name': 'Other'},
  ];

  // Predefined colors
  final List<Color> _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Colors.purple,
    Colors.indigo,
    Colors.teal,
    Colors.cyan,
    Colors.pink,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _selectedIcon = IconData(widget.category!.icon, fontFamily: 'MaterialIcons');
      _selectedColor = Color(widget.category!.color);
    } else {
      _selectedIcon = IconData(_categoryIcons[0]['icon'], fontFamily: 'MaterialIcons'); // Fixed
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final language = authProvider.userModel?.locale?.split('_').first ?? 'en';
        
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.category != null 
                ? TranslationHelper.getText('edit_category', language)
                : TranslationHelper.getText('add_category', language)),
            elevation: 0,
            actions: [
              if (widget.category != null)
                TextButton(
                  onPressed: _isLoading ? null : _deleteCategory,
                  child: Text(
                    TranslationHelper.getText('delete', language),
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Card
              _buildPreviewCard(language),
              const SizedBox(height: 32),

              // Category Name
              _buildSectionTitle(TranslationHelper.getText('category_name', language)),
              const SizedBox(height: 8),
              _buildNameInput(language),
              const SizedBox(height: 24),

              // Description
              _buildSectionTitle(TranslationHelper.getText('description_optional', language)),
              const SizedBox(height: 8),
              _buildDescriptionInput(language),
              const SizedBox(height: 24),

              // Icon Selection
              _buildSectionTitle(TranslationHelper.getText('choose_icon', language)),
              const SizedBox(height: 8),
              _buildIconSelector(),
              const SizedBox(height: 24),

              // Color Selection
              _buildSectionTitle(TranslationHelper.getText('choose_color', language)),
              const SizedBox(height: 8),
              _buildColorSelector(),
              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(language),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPreviewCard(String language) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selectedColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            TranslationHelper.getText('preview', language),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIcon ?? Icons.category,
                  color: _selectedColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty 
                          ? TranslationHelper.getText('category_name', language)
                          : _nameController.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _nameController.text.isEmpty
                            ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                            : null,
                      ),
                    ),
                    if (_descriptionController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _descriptionController.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(String language) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: TranslationHelper.getText('category_name_hint', language),
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return TranslationHelper.getText('please_enter_category_name', language);
        }
        if (value.trim().length < 2) {
          return TranslationHelper.getText('category_name_min_length', language);
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildDescriptionInput(String language) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: TranslationHelper.getText('category_description_hint', language),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildIconSelector() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _categoryIcons.length,
        itemBuilder: (context, index) {
          final iconData = _categoryIcons[index];
          final isSelected = _selectedIcon?.codePoint == iconData['icon']; // Fixed comparison

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = IconData(iconData['icon'], fontFamily: 'MaterialIcons'); // Fixed assignment
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? _selectedColor.withOpacity(0.2)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? _selectedColor
                      : Theme.of(context).dividerColor.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                IconData(iconData['icon'], fontFamily: 'MaterialIcons'),
                color: isSelected
                    ? _selectedColor
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _colors.map((color) {
          final isSelected = _selectedColor.value == color.value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton(String language) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveCategory,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(
        widget.category != null 
            ? TranslationHelper.getText('update_category', language)
            : TranslationHelper.getText('create_category', language),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIcon == null) {
      final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
      _showErrorSnackBar(TranslationHelper.getText('please_select_icon', language));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';
      if (userId.isEmpty) {
        final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
        _showErrorSnackBar(TranslationHelper.getText('user_not_authenticated', language));
        return;
      } // replace with your AuthProvider user id
      final type = 'expense'; // adjust based on your UI selection

      if (widget.category != null) {
        // Update existing category
        final updatedCategory = CategoryModel(
          id: widget.category!.id,
          userId: userId,
          type: type,
          name: name,
          description: description.isEmpty ? '' : description,
          icon: _selectedIcon!.codePoint,
          color: _selectedColor.value,
          isDefault: widget.category!.isDefault,
          createdAt: widget.category!.createdAt,
          updatedAt: DateTime.now(),
        );

        await categoryProvider.updateCategory(updatedCategory);
        final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
        _showSuccessSnackBar(TranslationHelper.getText('category_updated_successfully', language));
      } else {
        // Create new category
        final newCategory = CategoryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: type,
          name: name,
          description: description.isEmpty ? '' : description,
          icon: _selectedIcon!.codePoint,
          color: _selectedColor.value,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await categoryProvider.addCategory(newCategory);
        final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
        _showSuccessSnackBar(TranslationHelper.getText('category_created_successfully', language));
      }

      Navigator.of(context).pop();
    } catch (e) {
      final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
      _showErrorSnackBar('${TranslationHelper.getText('failed_to_save_category', language)}: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteCategory() async {
    if (widget.category == null) return;

    final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
    final confirmed = await _showConfirmDialog(
      TranslationHelper.getText('delete_category', language),
      '${TranslationHelper.getText('confirm_delete_category', language)} "${widget.category!.name}"? ${TranslationHelper.getText('action_cannot_be_undone', language)}',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.deleteCategory(widget.category!.id);
      final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
      _showSuccessSnackBar(TranslationHelper.getText('category_deleted_successfully', language));
      Navigator.of(context).pop();
    } catch (e) {
      final language = context.read<AuthProvider>().userModel?.locale?.split('_').first ?? 'en';
      _showErrorSnackBar('${TranslationHelper.getText('failed_to_delete_category', language)}: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final language = authProvider.userModel?.locale?.split('_').first ?? 'en';
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(TranslationHelper.getText('cancel', language)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(TranslationHelper.getText('delete', language)),
              ),
            ],
          );
        },
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}