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