import 'package:flutter/material.dart';
import 'package:production_app/services/sheets_service.dart';

class ProductionProvider extends ChangeNotifier {
  final SheetsService service;
  bool _loading = false;

  ProductionProvider(this.service);

  bool get loading => _loading;

  Future<void> saveProduction(String employeeId, Map<String, int> quantities) async {
    _loading = true;
    notifyListeners();

    try {
      await service.saveProductionBatch(employeeId, quantities);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
