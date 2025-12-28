# Flutter + Google Sheets API
## Production Data Capture App (Intermediate Level)

---

## 1. Project Overview
This guide explains how to build a **Flutter mobile application** that performs **CRUD operations** directly on **Google Sheets** using a **Service Account**, without a custom backend.

### Use case
Employees record daily production:
- Select **Category**
- View **Products** in that category
- Enter **Production Quantity**
- Data stored with:
  - Date
  - Employee ID
  - Product ID

Google Sheets acts as a **visible database**.

---

## 2. Technology Stack
- Flutter (Android)
- Google Sheets API
- Google Drive API
- Service Account authentication
- HTTP (REST)

---

## 3. Google Sheets Data Model

### Sheet: `CATEGORIES`
| category_id | name |

### Sheet: `PRODUCTS`
| product_id | category_id | name |

### Sheet: `EMPLOYEES`
| employee_id | name |

### Sheet: `PRODUCTION`
| date | employee_id | product_id | quantity |

---

## 4. Google Cloud Configuration (CRITICAL)

### 4.1 Create Project
- Google Cloud Console → New Project

### 4.2 Enable APIs
Enable:
- Google Sheets API
- Google Drive API

### 4.3 Create Service Account
IAM & Admin → Service Accounts
- Name: `sheets-production-app`
- Role: **Editor**

### 4.4 Generate JSON Key
- Create key → JSON
- Download securely

### 4.5 Share Spreadsheet
Share the Google Sheet with:
```
xxxxx@project-id.iam.gserviceaccount.com
```
Permission: **Editor**

---

## 5. Flutter Project Structure (Clean Layers)

> **Code location convention (IMPORTANT):**
> From this section onward, **each code block is preceded by a markdown heading that explicitly indicates the file path** where that code must be placed.
>
> Example:
> ```md
> ### lib/services/sheets_service.dart
> ```
> ```dart
> // code here
> ```
>
> This avoids ambiguity and keeps the guide copy‑paste friendly.



```
lib/
 ├── core/
 │    └── config.dart
 ├── models/
 │    ├── category.dart
 │    ├── product.dart
 │    ├── employee.dart
 │    └── production.dart
 ├── services/
 │    └── sheets_service.dart
 ├── providers/
 │    ├── category_provider.dart
 │    ├── product_provider.dart
 │    └── production_provider.dart
 ├── ui/
 │    ├── screens/
 │    └── widgets/
 └── main.dart
```

---

## 6. Bash Script – Project Bootstrap (Linux)

```bash
#!/bin/bash
flutter create production_app
cd production_app

mkdir -p lib/{core,models,services,providers,ui/screens,ui/widgets}

touch lib/core/config.dart

touch lib/models/{category.dart,product.dart,employee.dart,production.dart}

touch lib/services/sheets_service.dart

touch lib/providers/{category_provider.dart,product_provider.dart,production_provider.dart}
```

---

## 7. Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.2
  googleapis: ^13.2.0
  googleapis_auth: ^1.4.1
```

---

## 8. Google Sheets Service (Core Logic)

```dart
// FILE: (see section title above for exact path)

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
}
```

---

## 9. CRUD Example – Insert Production Record

```dart
// FILE: (see section title above for exact path)

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
```

---

## 10. Security Notes
- Do not commit `credentials.json`
- Obfuscate Flutter build
- Limit sheet permissions
- Validate input before sending

---

## 11. API Limits
- 500 requests / 100 seconds / project
- Batch updates recommended

---

## 12. Future Migration Path
- Replace SheetsService with REST backend
- Move to PostgreSQL / MongoDB
- Keep same UI and Providers

---

## 13. UI FLOW (Flutter Screens)

### Screens
- EmployeeLoginScreen (enter/select employee ID)
- CategorySelectionScreen
- ProductProductionScreen
- ProductionSummaryScreen (optional)

### UI Flow
```
Employee → Select Category → View Products → Enter Quantity → Save
```

### Widgets
- CategoryDropdown
- ProductTableRow
- QuantityInputField
- SaveButton

---

## 14. READ OPERATIONS – Core Logic (STEP 1)

### 14.1 Read Categories

```dart
// FILE: (see section title above for exact path)

Future<List<Category>> fetchCategories() async {
  final client = await getClient();
  final api = SheetsApi(client);

  final response = await api.spreadsheets.values.get(
    spreadsheetId,
    'CATEGORIES!A2:B',
  );

  return response.values!.map((row) => Category(
    id: row[0],
    name: row[1],
  )).toList();
}
```

---

### 14.2 Read Products by Category

```dart
// FILE: (see section title above for exact path)

Future<List<Product>> fetchProductsByCategory(String categoryId) async {
  final client = await getClient();
  final api = SheetsApi(client);

  final response = await api.spreadsheets.values.get(
    spreadsheetId,
    'PRODUCTS!A2:C',
  );

  return response.values!
      .where((row) => row[1] == categoryId)
      .map((row) => Product(
            id: row[0],
            categoryId: row[1],
            name: row[2],
          ))
      .toList();
}
```

---

### 14.3 Category Provider

```dart
// FILE: (see section title above for exact path)

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
```

---

### 14.4 Product Provider

```dart
// FILE: (see section title above for exact path)

class ProductProvider extends ChangeNotifier {
  final SheetsService service;
  List<Product> products = [];

  ProductProvider(this.service);

  Future<void> loadProducts(String categoryId) async {
    products = await service.fetchProductsByCategory(categoryId);
    notifyListeners();
  }
}
```

---

### 14.5 Category Selection Screen (Logic)

```dart
// FILE: (see section title above for exact path)

Consumer<CategoryProvider>(
  builder: (_, provider, __) {
    if (provider.loading) return CircularProgressIndicator();

    return DropdownButton<Category>(
      items: provider.categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c.name),
        );
      }).toList(),
      onChanged: (category) {
        context.read<ProductProvider>()
          .loadProducts(category!.id);
      },
    );
  },
)
```

---

## 15. UI – Complete Navigation & Production Entry (STEP 2)

### 15.1 Employee Login Screen

```dart
// FILE: (see section title above for exact path)

class EmployeeLoginScreen extends StatefulWidget {
  @override
  _EmployeeLoginScreenState createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Employee ID'),
            ),
            ElevatedButton(
              child: Text('Continue'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategorySelectionScreen(
                      employeeId: controller.text,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
```

---

### 15.2 Category Selection Screen

```dart
// FILE: (see section title above for exact path)

class CategorySelectionScreen extends StatelessWidget {
  final String employeeId;

  CategorySelectionScreen({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    context.read<CategoryProvider>().loadCategories();

    return Scaffold(
      appBar: AppBar(title: Text('Select Category')),
      body: Consumer<CategoryProvider>(
        builder: (_, provider, __) {
          return ListView(
            children: provider.categories.map((c) {
              return ListTile(
                title: Text(c.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductProductionScreen(
                        employeeId: employeeId,
                        category: c,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
```

---

### 15.3 Product Production Screen (Editable Table)

```dart
// FILE: (see section title above for exact path)

class ProductProductionScreen extends StatefulWidget {
  final String employeeId;
  final Category category;

  ProductProductionScreen({required this.employeeId, required this.category});

  @override
  _ProductProductionScreenState createState() => _ProductProductionScreenState();
}

class _ProductProductionScreenState extends State<ProductProductionScreen> {
  final Map<String, int> quantities = {};

  @override
  Widget build(BuildContext context) {
    context.read<ProductProvider>()
      .loadProducts(widget.category.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          return ListView(
            children: provider.products.map((p) {
              return ListTile(
                title: Text(p.name),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      quantities[p.id] = int.tryParse(v) ?? 0;
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () {
          // batch save handled in next step
        },
      ),
    );
  }
}
```

---

## 16. CONTROL & SECURITY – STEP 4 (Intermediate)

### 16.1 Persist Employee ID (SharedPreferences)

```dart
// FILE: (see section title above for exact path)

Future<void> saveEmployeeId(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('employee_id', id);
}

Future<String?> getEmployeeId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('employee_id');
}
```

---

### 16.2 Date Handling (One Record per Day)

```dart
// FILE: (see section title above for exact path)

String today() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
```

---

### 16.3 Check Existing Production Record

```dart
// FILE: (see section title above for exact path)

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

  return response.values!.any((row) =>
    row[0] == date &&
    row[1] == employeeId &&
    row[2] == productId
  );
}
```

---

### 16.4 Batch Insert / Update Production

```dart
// FILE: (see section title above for exact path)

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
```

---

### 16.5 Validation Rules Enforced
- Employee ID must exist
- Quantity >= 0
- One entry per product per day
- No empty batch submission

---

## 17. Export to PDF

```bash
pandoc FlutterSheetsProductionGuide.md -o FlutterSheetsProductionGuide.pdf
```

---

## END OF GUIDE
