import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/providers/category_provider.dart';
import 'package:production_app/ui/screens/product_production_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String employeeId;

  CategorySelectionScreen({required this.employeeId});

  @override
  _CategorySelectionScreenState createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Call loadCategories after the first frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Category')),
      body: Consumer<CategoryProvider>(
        builder: (_, provider, __) {
          if (provider.loading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return Center(child: Text('No categories found.'));
          }
          return ListView(
            children: provider.categories.map((c) {
              return ListTile(
                title: Text(c.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductProductionScreen(
                        employeeId: widget.employeeId, // Access employeeId via widget
                        category: c,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
