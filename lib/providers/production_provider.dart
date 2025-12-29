import 'package:flutter/material.dart';
import 'package:production_app/services/sheets_service.dart';
import 'package:production_app/models/production.dart'; // Import Production model

class ProductionProvider extends ChangeNotifier {
  final SheetsService service;
  bool _loading = false;
  int _productionCount = 0;
  List<Production> _productionRecords = []; // Changed to List<Production>

  ProductionProvider(this.service);

  bool get loading => _loading;
  int get productionCount => _productionCount;
  List<Production> get productionRecords => _productionRecords; // Changed getter

  Future<void> saveProduction(String employeeId, Map<String, Map<String, dynamic>> productionData) async {
    _loading = true;
    _productionCount = 0;
    _productionRecords = []; // Cleared the list
    notifyListeners();

    try {
      await service.saveProductionBatch(employeeId, productionData);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> getTodaysProductionCount(String employeeId) async {
    _loading = true;
    notifyListeners();
    try {
      _productionCount = await service.getTodaysProductionCount(employeeId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductionRecords(String employeeId) async {
    _loading = true;
    notifyListeners();
    try {
      _productionRecords = await service.fetchAllProductionRecords(employeeId, today()); // Fetches List<Production>
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

