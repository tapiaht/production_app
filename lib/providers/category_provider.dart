import 'package:flutter/material.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/services/sheets_service.dart';

class CategoryProvider extends ChangeNotifier {
  final SheetsService service;
  List<Category> categories = [];
  bool loading = false;

  CategoryProvider(this.service);

  Future<void> loadCategories() async {
    loading = true;
    notifyListeners();

    categories = await service.fetchCategories();
    loading = false;
    notifyListeners();
  }
}
