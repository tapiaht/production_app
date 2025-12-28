import 'package:flutter/material.dart';
import 'package:production_app/services/sheets_service.dart';

class ProductionProvider extends ChangeNotifier {
  final SheetsService service;
  bool _loading = false;
  int _productionCount = 0;
  Map<String, int> _productionRecords = {};

  ProductionProvider(this.service);

  bool get loading => _loading;
  int get productionCount => _productionCount;
  Map<String, int> get productionRecords => _productionRecords;

  Future<void> saveProduction(String employeeId, Map<String, int> quantities) async {
    _loading = true;
    _productionCount = 0;
    _productionRecords = {};
    notifyListeners();

    try {
      await service.saveProductionBatch(employeeId, quantities);
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
      _productionRecords = await service.fetchAllProductionRecords(employeeId, today());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
