import 'package:flutter/material.dart';
import 'package:safar/models/category_model.dart';
import 'package:safar/core/utils/translation_helper.dart';

class CategorySelector extends StatefulWidget {
  final List<CategoryModel> categories;
  final String currentLanguage; // 'en', 'es', etc.

  const CategorySelector({
    Key? key,
    required this.categories,
    this.currentLanguage = 'en',
  }) : super(key: key);

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  CategoryModel? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.getText('select_category', widget.currentLanguage),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildCategorySelection(widget.categories),
      ],
    );
  }

  Widget _buildCategorySelection(List<CategoryModel> categories) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: _buildCategoryTile(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(CategoryModel category) {
    final categoryName = category.getLocalizedName(widget.currentLanguage);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: category.colorData.withOpacity(0.2),
            child: Icon(category.iconData, color: category.colorData),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              categoryName,
              style: TextStyle(
                color: category.colorData,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
