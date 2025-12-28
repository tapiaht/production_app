import 'package:flutter/material.dart';
import 'package:production_app/services/sheets_service.dart';

class ProductionProvider extends ChangeNotifier {
  final SheetsService service;
  bool _loading = false;
  int _productionCount = 0;

  ProductionProvider(this.service);

  bool get loading => _loading;
  int get productionCount => _productionCount;

  Future<void> saveProduction(String employeeId, Map<String, int> quantities) async {
    _loading = true;
    _productionCount = 0;
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
}
