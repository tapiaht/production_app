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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int> quantities = {};
  bool _isDataLoaded = false; // Add a flag to track data loading

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final productionProvider = Provider.of<ProductionProvider>(context, listen: false);

      // Load products first
      await productProvider.loadProducts(widget.category.id);

      // Then load production records
      await productionProvider.loadProductionRecords(widget.employee.id);

      // After loading both, initialize quantities and controllers
      final productionRecords = productionProvider.productionRecords;
      for (var product in productProvider.products) {
        final initialQuantity = productionRecords[product.id] ?? 0;
        quantities[product.id] = initialQuantity;
        _controllers[product.id] = TextEditingController(text: initialQuantity == 0 ? '' : initialQuantity.toString());
      }
      
      // Finally, load today's production count
      await productionProvider.getTodaysProductionCount(widget.employee.id);

      // Set flag and trigger a rebuild to update the UI with pre-filled text fields
      setState(() {
        _isDataLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _saveProduction(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Filter out products with 0 quantity or empty input
    final quantitiesToSave = Map<String, int>.from(quantities)..removeWhere((key, value) => value == 0);

    if (quantitiesToSave.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please enter quantities for at least one product.')),
      );
      return;
    }

    final productionProvider = Provider.of<ProductionProvider>(context, listen: false);

    try {
      await productionProvider.saveProduction(widget.employee.id, quantitiesToSave);
      
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
    // Moved loadProducts to initState to prevent setState() during build error.
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
                if (provider.loading || !_isDataLoaded) { // Check _isDataLoaded as well
                  return Center(child: CircularProgressIndicator());
                }
                if (provider.products.isEmpty) {
                  return Center(child: Text('No products found for this category.'));
                }
                return ListView.builder(
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    // Retrieve pre-initialized controller
                    final controller = _controllers[product.id]; 
                    
                    return ListTile(
                      title: Text(product.name),
                      trailing: SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller, // Use the pre-initialized controller
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                          ),
                          onChanged: (v) {
                            quantities[product.id] = int.tryParse(v) ?? 0;
                          },
                        ),
                      ),
                    );
                  },
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
