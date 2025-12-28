import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/providers/product_provider.dart';
import 'package:production_app/services/sheets_service.dart'; // Import SheetsService

class ProductProductionScreen extends StatefulWidget {
  final String employeeId;
  final Category category;

  ProductProductionScreen({required this.employeeId, required this.category});

  @override
  _ProductProductionScreenState createState() => _ProductProductionScreenState();
}

class _ProductProductionScreenState extends State<ProductProductionScreen> {
  final Map<String, int> quantities = {};
  bool _isSaving = false;

  void _saveProduction() async {
    if (quantities.isEmpty || quantities.values.every((qty) => qty == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter quantities for at least one product.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sheetsService = Provider.of<SheetsService>(context, listen: false); // Access SheetsService
      await sheetsService.saveProductionBatch(widget.employeeId, quantities);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Production saved successfully!')),
      );
      Navigator.pop(context); // Go back after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save production: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<ProductProvider>()
      .loadProducts(widget.category.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          if (provider.products.isEmpty) {
            return Center(child: Text('No products found for this category.'));
          }
          return ListView(
            children: provider.products.map((p) {
              return ListTile(
                title: Text(p.name),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      quantities[p.id] = int.tryParse(v) ?? 0;
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: _isSaving
          ? CircularProgressIndicator()
          : FloatingActionButton(
              child: Icon(Icons.save),
              onPressed: _saveProduction,
            ),
    );
  }
}
