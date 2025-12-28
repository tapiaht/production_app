import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/providers/category_provider.dart';
import 'package:production_app/providers/product_provider.dart';
import 'package:production_app/providers/employee_provider.dart';
import 'package:production_app/providers/production_provider.dart';
import 'package:production_app/services/sheets_service.dart';
import 'package:production_app/ui/screens/employee_login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final sheetsService = SheetsService();

    return MultiProvider(
      providers: [
        Provider<SheetsService>(create: (_) => sheetsService), // Provide SheetsService
        ChangeNotifierProvider(create: (_) => CategoryProvider(sheetsService)),
        ChangeNotifierProvider(create: (_) => ProductProvider(sheetsService)),
        ChangeNotifierProvider(create: (_) => EmployeeProvider(sheetsService)),
        ChangeNotifierProvider(create: (_) => ProductionProvider(sheetsService)),
      ],
      child: MaterialApp(
        title: 'Production App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: EmployeeLoginScreen(),
      ),
    );
  }
}