import 'package:flutter/material.dart';
import 'package:production_app/models/product.dart';
import 'package:production_app/services/sheets_service.dart';

class ProductProvider extends ChangeNotifier {
  final SheetsService service;
  List<Product> products = [];

  ProductProvider(this.service);

  Future<void> loadProducts(String categoryId) async {
    products = await service.fetchProductsByCategory(categoryId);
    notifyListeners();
  }
}
