import 'package:flutter/material.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/services/sheets_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final SheetsService service;
  List<Employee> employees = [];
  bool loading = false;

  EmployeeProvider(this.service);

  Future<void> loadEmployees() async {
    loading = true;
    notifyListeners();

    employees = await service.fetchEmployees();
    loading = false;
    notifyListeners();
  }
}
