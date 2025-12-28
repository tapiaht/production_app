import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/models/product.dart';
import 'package:production_app/providers/category_provider.dart';
import 'package:production_app/providers/employee_provider.dart';
import 'package:production_app/providers/product_provider.dart';
import 'package:production_app/providers/production_provider.dart';
import 'package:production_app/services/sheets_service.dart';
import 'package:production_app/ui/screens/product_production_screen.dart';

// --- FAKE Implementations of Providers for Testing ---

// Not strictly necessary to extend, but shows it's a stand-in
class FakeSheetsService extends SheetsService {
  FakeSheetsService() : super(); // Corrected constructor
}

class FakeEmployeeProvider extends EmployeeProvider {
  Employee? _employeeById;
  FakeEmployeeProvider() : super(FakeSheetsService());

  void setEmployeeById(Employee? employee) {
    _employeeById = employee;
  }

  @override
  Employee? getEmployeeById(String id) => _employeeById;

  @override
  Future<void> loadEmployees() async { /* do nothing for this test */ }
}

class FakeCategoryProvider extends CategoryProvider {
  List<Category> _categories = [];
  bool _loading = false;
  FakeCategoryProvider() : super(FakeSheetsService());

  void setCategories(List<Category> categories) {
    _categories = categories;
  }
  @override
  List<Category> get categories => _categories;
  @override
  bool get loading => _loading;

  @override
  Future<void> loadCategories() async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 10)); // Simulate async
    _loading = false;
    notifyListeners();
  }
}

class FakeProductProvider extends ProductProvider {
  List<Product> _products = [];
  bool _loading = false;
  FakeProductProvider() : super(FakeSheetsService());

  void setProducts(List<Product> products) {
    _products = products;
  }

  @override
  List<Product> get products => _products;
  @override
  bool get loading => _loading;

  @override
  Future<void> loadProducts(String categoryId) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 10)); // Simulate async
    _loading = false;
    notifyListeners();
  }
}

class FakeProductionProvider extends ProductionProvider {
  int _productionCount = 0;
  Map<String, int> _productionRecords = {};
  bool _loading = false;

  FakeProductionProvider() : super(FakeSheetsService());

  void setProductionCount(int count) {
    _productionCount = count;
  }

  void setProductionRecords(Map<String, int> records) {
    _productionRecords = records;
  }

  @override
  int get productionCount => _productionCount;
  @override
  Map<String, int> get productionRecords => _productionRecords;
  @override
  bool get loading => _loading;

  @override
  Future<void> saveProduction(String employeeId, Map<String, int> quantities) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 10)); // Simulate async
    _loading = false;
    // Update internal state as if saved
    _productionRecords.addAll(quantities);
    _productionCount = _productionRecords.length; // Simplified
    notifyListeners();
  }

  @override
  Future<void> getTodaysProductionCount(String employeeId) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 10)); // Simulate async
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> loadProductionRecords(String employeeId) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 10)); // Simulate async
    _loading = false;
    notifyListeners();
  }
}


void main() {
  group('ProductProductionScreen', () {
    late FakeCategoryProvider fakeCategoryProvider;
    late FakeEmployeeProvider fakeEmployeeProvider;
    late FakeProductProvider fakeProductProvider;
    late FakeProductionProvider fakeProductionProvider;

    final tEmployee = Employee(id: 'marcos', name: 'Marcos', password: '123');
    final tCategoryVerduras = Category(id: 'verduras', name: 'Verduras');
    final tCategorySalsas = Category(id: 'salsas', name: 'Salsas');
    final tProductSalteado = Product(id: 'salteado', categoryId: 'verduras', name: 'Salteado');
    final tProductTomatada = Product(id: 'tomatada', categoryId: 'salsas', name: 'Tomatada');

    setUp(() {
      fakeCategoryProvider = FakeCategoryProvider();
      fakeEmployeeProvider = FakeEmployeeProvider();
      fakeProductProvider = FakeProductProvider();
      fakeProductionProvider = FakeProductionProvider();

      fakeEmployeeProvider.setEmployeeById(tEmployee);
      fakeCategoryProvider.setCategories([]); // Default empty
      fakeProductProvider.setProducts([]); // Default empty
      fakeProductionProvider.setProductionRecords({}); // Default empty
      fakeProductionProvider.setProductionCount(0); // Default zero
    });

    Widget createProductProductionScreen({
      required Employee employee,
      required Category category,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoryProvider>(create: (_) => fakeCategoryProvider),
          ChangeNotifierProvider<EmployeeProvider>(create: (_) => fakeEmployeeProvider),
          ChangeNotifierProvider<ProductProvider>(create: (_) => fakeProductProvider),
          ChangeNotifierProvider<ProductionProvider>(create: (_) => fakeProductionProvider),
        ],
        child: MaterialApp(
          home: ProductProductionScreen(employee: employee, category: category),
        ),
      );
    }

    testWidgets('loads and displays product quantities for Verduras (Salteado 8)', (tester) async {
      final productsVerduras = [tProductSalteado];
      final productionRecordsVerduras = {tProductSalteado.id: 8};

      fakeProductProvider.setProducts(productsVerduras);
      fakeProductionProvider.setProductionRecords(productionRecordsVerduras);

      await tester.pumpWidget(createProductProductionScreen(
        employee: tEmployee,
        category: tCategoryVerduras,
      ));

      // Wait for initializations and data loading
      await tester.pumpAndSettle();

      // Verify StatusBar
      expect(find.text('Employee: Marcos'), findsOneWidget);
      expect(find.text('Today\'s Records: 0'), findsOneWidget); 

      // Verify product list and quantities
      expect(find.text('Salteado'), findsOneWidget);
      final salteadoTextField = find.widgetWithText(TextField, '8');
      expect(salteadoTextField, findsOneWidget);
      
      final TextField salteadoInput = tester.widget(salteadoTextField);
      expect(salteadoInput.controller!.text, '8');

      // Verify methods were called
      // verify(mockProductionProvider.loadProductionRecords(tEmployee.id)).called(1); // Not using mockito
      // verify(mockProductProvider.loadProducts(tCategoryVerduras.id)).called(1); // Not using mockito
    });

    testWidgets('loads and displays product quantities for Salsas (Tomatada 2)', (tester) async {
      final productsSalsas = [tProductTomatada];
      final productionRecordsSalsas = {tProductTomatada.id: 2};

      fakeProductProvider.setProducts(productsSalsas);
      fakeProductionProvider.setProductionRecords(productionRecordsSalsas);

      await tester.pumpWidget(createProductProductionScreen(
        employee: tEmployee,
        category: tCategorySalsas,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Employee: Marcos'), findsOneWidget);
      expect(find.text('Today\'s Records: 0'), findsOneWidget);

      expect(find.text('Tomatada'), findsOneWidget);
      final tomatadaTextField = find.widgetWithText(TextField, '2');
      expect(tomatadaTextField, findsOneWidget);

      final TextField tomatadaInput = tester.widget(tomatadaTextField);
      expect(tomatadaInput.controller!.text, '2');
    });

    testWidgets('TextField shows Qty when no previous record', (tester) async {
      final productsVerduras = [tProductSalteado]; 

      fakeProductProvider.setProducts(productsVerduras);
      fakeProductionProvider.setProductionRecords({});

      await tester.pumpWidget(createProductProductionScreen(
        employee: tEmployee,
        category: tCategoryVerduras,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Salteado'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Qty'), findsOneWidget);
      
      final TextField salteadoInput = tester.widget(find.byType(TextField));
      expect(salteadoInput.controller!.text, ''); 
    });
  });
}
