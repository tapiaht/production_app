import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/providers/category_provider.dart';
import 'package:production_app/ui/screens/product_production_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String employeeId;

  const CategorySelectionScreen({super.key, required this.employeeId});

  @override
  State<CategorySelectionScreen> createState() => CategorySelectionScreenState();
}

class CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Call loadCategories after the first frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategoryId = category.id;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductProductionScreen(
          employeeId: widget.employeeId, // Access employeeId via widget
          category: category,
        ),
      ),
    ).then((_) {
      setState(() {
        _selectedCategoryId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Category')),
      body: Consumer<CategoryProvider>(
        builder: (_, provider, _) { // Changed __ to _
          if (provider.loading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return Center(child: Text('No categories found.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return _CategoryGridItem(
                category: category,
                isSelected: _selectedCategoryId == category.id,
                onTap: () => _onCategorySelected(category),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5),
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category, size: 48.0, color: Theme.of(context).primaryColor),
              SizedBox(height: 8.0),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
