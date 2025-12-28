import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:production_app/core/config.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/models/product.dart';
import 'package:production_app/models/employee.dart';

class SheetsService {
  final _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive'
  ];

  Future<AuthClient> getClient() async {
    final json = await rootBundle.loadString('assets/credentials.json');
    final account = ServiceAccountCredentials.fromJson(json);
    return clientViaServiceAccount(account, _scopes);
  }

  Future<void> insertProduction(
    String employeeId,
    String productId,
    int quantity,
  ) async {
    final client = await getClient();
    final sheetsApi = SheetsApi(client);

    final valueRange = ValueRange(values: [[
      DateTime.now().toIso8601String(),
      employeeId,
      productId,
      quantity
    ]]);

    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'PRODUCTION!A:D',
      valueInputOption: 'RAW',
    );
  }

  Future<List<Category>> fetchCategories() async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'CATEGORIES!A2:B',
    );

    if (response.values == null || response.values!.isEmpty) {
      return [];
    }

    return response.values!.map((row) => Category(
      id: row[0].toString(),
      name: row[1].toString(),
    )).toList();
  }

  Future<List<Employee>> fetchEmployees() async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'EMPLOYEES!A2:C',
    );

    if (response.values == null || response.values!.isEmpty) {
      return [];
    }

    return response.values!
      .where((row) => row.length > 2)
      .map((row) => Employee(
        id: row[0].toString(),
        name: row[1].toString(),
        password: row[2].toString(),
    )).toList();
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTS!A2:C',
    );

    if (response.values == null || response.values!.isEmpty) {
      return [];
    }

    return response.values!
        .where((row) => row[1].toString() == categoryId)
        .map((row) => Product(
              id: row[0].toString(),
              categoryId: row[1].toString(),
              name: row[2].toString(),
            ))
        .toList();
  }

  Future<bool> productionExists(
    String date,
    String employeeId,
    String productId,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A2:D',
    );

    if (response.values == null) {
      return false;
    }

    return response.values!.any((row) =>
      row.length > 2 && // Ensure there are enough columns to compare
      row[0].toString() == date &&
      row[1].toString() == employeeId &&
      row[2].toString() == productId
    );
  }

  Future<void> saveProductionBatch(
    String employeeId,
    Map<String, int> quantities,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);
    final date = today();

    final rows = quantities.entries.map((e) => [
      date,
      employeeId,
      e.key,
      e.value
    ]).toList();

    final body = ValueRange(values: rows);

    await api.spreadsheets.values.append(
      body,
      spreadsheetId,
      'PRODUCTION!A:D',
      valueInputOption: 'RAW',
    );
  }
}

String today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

