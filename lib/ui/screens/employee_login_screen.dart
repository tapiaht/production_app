import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/providers/employee_provider.dart';
import 'package:production_app/ui/screens/category_selection_screen.dart';
import 'package:production_app/services/local_storage_service.dart';

class EmployeeLoginScreen extends StatefulWidget {
  @override
  _EmployeeLoginScreenState createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).loadEmployees();
    });
  }

  void _continueToCategories() async {
    if (_selectedEmployee != null) {
      await _localStorageService.saveEmployeeId(_selectedEmployee!.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategorySelectionScreen(employeeId: _selectedEmployee!.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an employee')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Employee')),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.employees.isEmpty) {
            return Center(child: Text('No employees found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<Employee>(
                  hint: Text('Select an employee'),
                  isExpanded: true,
                  value: _selectedEmployee,
                  onChanged: (Employee? newValue) {
                    setState(() {
                      _selectedEmployee = newValue;
                    });
                  },
                  items: provider.employees.map((Employee employee) {
                    return DropdownMenuItem<Employee>(
                      value: employee,
                      child: Text(employee.name),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Continue'),
                  onPressed: _continueToCategories,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
