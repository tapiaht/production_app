import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/providers/product_provider.dart';
import 'package:production_app/providers/production_provider.dart';
import 'package:production_app/ui/widgets/status_bar.dart';

class ProductProductionScreen extends StatefulWidget {
  final Employee employee;
  final Category category;

  const ProductProductionScreen({super.key, required this.employee, required this.category});

  @override
  ProductProductionScreenState createState() => ProductProductionScreenState();
}

class ProductProductionScreenState extends State<ProductProductionScreen> {
  final Map<String, int> quantities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductionProvider>(context, listen: false)
          .getTodaysProductionCount(widget.employee.id);
    });
  }

  void _saveProduction(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (quantities.isEmpty || quantities.values.every((qty) => qty == 0)) {
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please enter quantities for at least one product.')),
      );
      return;
    }

    final productionProvider = Provider.of<ProductionProvider>(context, listen: false);

    try {
      await productionProvider.saveProduction(widget.employee.id, quantities);
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Production saved successfully!')),
      );
      
      navigator.pop(); // Go back after saving
    } catch (e) {
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save production: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<ProductProvider>()
      .loadProducts(widget.category.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          Consumer<ProductionProvider>(
            builder: (context, productionProvider, child) {
              return StatusBar(
                employeeName: widget.employee.name,
                productionCount: productionProvider.productionCount,
              );
            },
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (_, provider, _) { // Changed __ to _
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
          ),
        ],
      ),
      floatingActionButton: Consumer<ProductionProvider>(
        builder: (context, productionProvider, _) { // Changed child to _
          return productionProvider.loading
              ? CircularProgressIndicator()
              : FloatingActionButton(
                  child: Icon(Icons.save),
                  onPressed: () => _saveProduction(context),
                );
        },
      ),
    );
  }
}
