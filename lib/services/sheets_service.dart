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
      today(),
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

  Future<int?> findProductionRecordRow(
    String employeeId,
    String productId,
    String date,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A:D',
    );

    if (response.values == null) {
      return null;
    }

    // +1 for 0-based index to 1-based row number
    // +1 because the header row is not included in the values
    for (int i = 0; i < response.values!.length; i++) {
      final row = response.values![i];
      if (row.length > 2 &&
          row[0].toString() == date &&
          row[1].toString() == employeeId &&
          row[2].toString() == productId) {
        return i + 2; // +2 because sheets are 1-indexed and has a header row
      }
    }
    return null;
  }

  Future<void> updateProductionRecord(
    int rowIndex,
    String employeeId,
    String productId,
    int newQuantity,
  ) async {
    final client = await getClient();
    final sheetsApi = SheetsApi(client);
    final date = today();

    final valueRange = ValueRange(values: [
      [date, employeeId, productId, newQuantity]
    ]);

    await sheetsApi.spreadsheets.values.update(
      valueRange,
      spreadsheetId,
      'PRODUCTION!A$rowIndex:D$rowIndex',
      valueInputOption: 'RAW',
    );
  }

  Future<Map<String, int>> fetchAllProductionRecords(
    String employeeId,
    String date,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A:D',
    );

    if (response.values == null) {
      return {};
    }

    final Map<String, int> records = {};
    for (final row in response.values!) {
      if (row.length > 3 &&
          row[0].toString() == date &&
          row[1].toString() == employeeId) {
        final productId = row[2].toString();
        final quantity = int.tryParse(row[3].toString()) ?? 0;
        records[productId] = quantity;
      }
    }
    return records;
  }

  Future<void> saveProductionBatch(
    String employeeId,
    Map<String, int> quantities,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);
    final date = today();

    final List<List<Object>> rowsToAppend = [];

    for (final entry in quantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;

      final rowIndex =
          await findProductionRecordRow(employeeId, productId, date);

      if (rowIndex != null) {
        await updateProductionRecord(rowIndex, employeeId, productId, quantity);
      } else {
        rowsToAppend.add([date, employeeId, productId, quantity]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      final body = ValueRange(values: rowsToAppend);
      await api.spreadsheets.values.append(
        body,
        spreadsheetId,
        'PRODUCTION!A:D',
        valueInputOption: 'RAW',
      );
    }
  }

  Future<int> getTodaysProductionCount(String employeeId) async {
    final client = await getClient();
    final api = SheetsApi(client);
    final date = today();

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A2:D',
    );

    if (response.values == null) {
      return 0;
    }

    return response.values!
        .where((row) =>
            row.length > 1 &&
            row[0].toString() == date &&
            row[1].toString() == employeeId)
        .length;
  }
}

String today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

