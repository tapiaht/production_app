import 'package:flutter/material.dart';
import 'package:production_app/models/product.dart';
import 'package:production_app/services/sheets_service.dart';

class ProductProvider extends ChangeNotifier {
  final SheetsService service;
  List<Product> products = [];
  bool _loading = false;

  ProductProvider(this.service);

  bool get loading => _loading;

  Future<void> loadProducts(String categoryId) async {
    _loading = true;
    notifyListeners();

    products = await service.fetchProductsByCategory(categoryId);
    _loading = false;
    notifyListeners();
  }
}
