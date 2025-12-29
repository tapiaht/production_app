import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:production_app/core/config.dart';
import 'package:production_app/models/category.dart';
import 'package:production_app/models/product.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/models/production.dart'; // Import Production model
import 'package:uuid/uuid.dart'; // Import the uuid package
import 'dart:developer'; // Import for log function

class SheetsService {
  final _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive'
  ];

  final _uuid = Uuid(); // Instantiate Uuid

  String generateUniqueId() {
    return _uuid.v4(); // Generate a UUID v4
  }

  Future<AuthClient> getClient() async {
    final json = await rootBundle.loadString('assets/credentials.json');
    final account = ServiceAccountCredentials.fromJson(json);
    return clientViaServiceAccount(account, _scopes);
  }

  Future<void> insertProduction(
    String productionId,
    String employeeId,
    String productId,
    int quantity,
  ) async {
    final client = await getClient();
    final sheetsApi = SheetsApi(client);

    final String recordDate = today();
    final valueRange = ValueRange(values: [[
      productionId,
      recordDate,
      employeeId,
      productId,
      quantity
    ]]);

    log('Inserting production: ID=$productionId, Date=$recordDate, Employee=$employeeId, Product=$productId, Quantity=$quantity to range PRODUCTION!A:E');
    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'PRODUCTION!A:E',
      valueInputOption: 'RAW',
    );
    log('Insert production completed.');
  }

  Future<List<Category>> fetchCategories() async {
    final client = await getClient();
    final api = SheetsApi(client);

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'CATEGORIES!A2:C',
    );

    if (response.values == null || response.values!.isEmpty) {
      log('No categories found.');
      return [];
    }

    log('Fetched ${response.values!.length} categories.');
    return response.values!.map((row) => Category(
      id: row[0].toString(),
      name: row[1].toString(),
      measure: row[2].toString(),
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
      log('No employees found.');
      return [];
    }

    log('Fetched ${response.values!.length} employees.');
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
      log('No products found for category $categoryId.');
      return [];
    }

    log('Fetched ${response.values!.length} products for category $categoryId.');
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

    log('Searching for record: Date="$date", Employee="$employeeId", Product="$productId"');
    log('Trimmed search parameters: Date="${date.trim()}", Employee="${employeeId.trim()}", Product="${productId.trim()}"');

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A:E',
    );

    if (response.values == null) {
      log('No production records found in sheet.');
      return null;
    }

    for (int i = 0; i < response.values!.length; i++) {
      final row = response.values![i];
      log('Evaluating row ${i + 2}: $row');

      if (row.length > 3) {
        final sheetDate = row[1].toString().trim();
        final sheetEmployeeId = row[2].toString().trim();
        final sheetProductId = row[3].toString().trim();

        log('  Sheet values (trimmed): Date="$sheetDate", Employee="$sheetEmployeeId", Product="$sheetProductId"');

        final dateMatch = sheetDate == date.trim();
        final employeeMatch = sheetEmployeeId == employeeId.trim();
        final productMatch = sheetProductId == productId.trim();

        log('  Comparison results: Date match=$dateMatch, Employee match=$employeeMatch, Product match=$productMatch');

        if (dateMatch && employeeMatch && productMatch) {
          log('Record found at row ${i + 2}.');
          return i + 2; // +2 because sheets are 1-indexed and has a header row
        }
      } else {
        log('  Row ${i + 2} has insufficient length for comparison (length: ${row.length}).');
      }
    }
    log('No matching record found.');
    return null;
  }

  Future<int?> findRowByProductionId(String productionId) async {
    final client = await getClient();
    final api = SheetsApi(client);

    log('Searching for record with productionId: "$productionId"');

    // Assuming a header row, start search from the second row.
    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A2:A',
    );

    if (response.values == null) {
      log('No production records found in sheet (searched from A2).');
      return null;
    }

    for (int i = 0; i < response.values!.length; i++) {
      final row = response.values![i];
      if (row.isNotEmpty && row[0].toString().trim() == productionId.trim()) {
        final rowIndex = i + 2; // +2 because the range starts from row 2.
        log('Record found at sheet row $rowIndex.');
        return rowIndex;
      }
    }
    log('No matching record found for productionId: "$productionId".');
    return null;
  }

  Future<void> updateProductionRecord(
    int rowIndex,
    String productionId,
    String employeeId,
    String productId,
    int newQuantity,
  ) async {
    final client = await getClient();
    final sheetsApi = SheetsApi(client);
    final String recordDate = today();

    final valueRange = ValueRange(values: [
      [productionId, recordDate, employeeId, productId, newQuantity]
    ]);

    log('Updating production record at row $rowIndex: ID=$productionId, Date=$recordDate, Employee=$employeeId, Product=$productId, Quantity=$newQuantity to range PRODUCTION!A$rowIndex:E$rowIndex');
    await sheetsApi.spreadsheets.values.update(
      valueRange,
      spreadsheetId,
      'PRODUCTION!A$rowIndex:E$rowIndex',
      valueInputOption: 'RAW',
    );
    log('Update production record completed.');
  }

  Future<List<Production>> fetchAllProductionRecords(
    String employeeId,
    String date,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);

    log('Fetching all production records for Employee=$employeeId, Date=$date');

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A:E',
    );

    if (response.values == null) {
      log('No production records found in sheet for fetchAll.');
      return [];
    }

    final List<Production> records = [];
    for (final row in response.values!) {
      if (row.length > 4 &&
          row[1].toString() == date &&
          row[2].toString() == employeeId) {
        records.add(Production(
          productionId: row[0].toString(),
          date: row[1].toString(),
          employeeId: row[2].toString(),
          productId: row[3].toString(),
          quantity: int.tryParse(row[4].toString()) ?? 0,
        ));
      }
    }
    log('Fetched ${records.length} matching production records.');
    return records;
  }

  Future<void> saveProductionBatch(
    String employeeId,
    Map<String, Map<String, dynamic>> productionData,
  ) async {
    final client = await getClient();
    final api = SheetsApi(client);
    final String recordDate = today();

    log('Starting saveProductionBatch for Employee=$employeeId, Date=$recordDate. Items to process: ${productionData.length}');

    final List<List<Object>> rowsToAppend = [];

    for (final entry in productionData.entries) {
      final productId = entry.key;
      final data = entry.value;
      final quantity = data['quantity'] as int;
      final productionId = data['productionId'] as String?;

      log('Processing Product=$productId, Quantity=$quantity, ProductionID=$productionId');

      if (productionId != null && productionId.isNotEmpty) {
        log('Existing record with ProductionID=$productionId. Attempting to update.');
        // Find row index using productionId
        final rowIndex = await findRowByProductionId(productionId);
        if (rowIndex != null) {
          await updateProductionRecord(rowIndex, productionId, employeeId, productId, quantity);
        } else {
          log('WARNING: ProductionID $productionId not found in sheet for product $productId. Creating a new record instead.');
          final newProductionId = generateUniqueId();
          rowsToAppend.add([newProductionId, recordDate, employeeId, productId, quantity]);
        }
      } else {
        log('No ProductionID for Product=$productId. Generating new productionId and adding to append list.');
        final newProductionId = generateUniqueId(); // Generate new ID
        rowsToAppend.add([newProductionId, recordDate, employeeId, productId, quantity]);
      }
    }

    if (rowsToAppend.isNotEmpty) {
      log('Appending ${rowsToAppend.length} new rows to PRODUCTION!A:E');
      final body = ValueRange(values: rowsToAppend);
      await api.spreadsheets.values.append(
        body,
        spreadsheetId,
        'PRODUCTION!A:E',
        valueInputOption: 'RAW',
      );
      log('Append completed.');
    }
    log('saveProductionBatch completed.');
  }

  Future<int> getTodaysProductionCount(String employeeId) async {
    final client = await getClient();
    final api = SheetsApi(client);
    final String recordDate = today();

    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      'PRODUCTION!A2:E',
    );

    if (response.values == null) {
      log('No production records found for count.');
      return 0;
    }

    final count = response.values!
        .where((row) =>
            row.length > 2 &&
            row[1].toString() == recordDate &&
            row[2].toString() == employeeId)
        .length;
    log('Today\'s production count for Employee=$employeeId is $count.');
    return count;
  }
}

String today() {
  final now = DateTime.now();
  final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  log('today() returns: $formattedDate');
  return formattedDate;
}

