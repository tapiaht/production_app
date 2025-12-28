import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:production_app/models/employee.dart';
import 'package:production_app/providers/employee_provider.dart';
import 'package:production_app/ui/screens/category_selection_screen.dart';
import 'package:production_app/services/local_storage_service.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});
  @override
  EmployeeLoginScreenState createState() => EmployeeLoginScreenState();
}

class EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).loadEmployees();
    });
  }

  void _onEmployeeSelected(Employee employee) {
    setState(() {
      _selectedEmployeeId = employee.id;
    });
    _showPasswordDialog(employee);
  }

  Future<void> _showPasswordDialog(Employee employee) async {
    final passwordController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must enter password
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password for ${employee.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (passwordController.text == employee.password) {
                  await _localStorageService.saveEmployeeId(employee.id);
                  
                  navigator.pop(); // Dismiss the dialog
                  
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => CategorySelectionScreen(employeeId: employee.id),
                    ),
                  );
                } else {
                  
                  navigator.pop(); // Dismiss the dialog
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _selectedEmployeeId = null;
      });
    });
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

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: provider.employees.length,
            itemBuilder: (context, index) {
              final employee = provider.employees[index];
              return _EmployeeGridItem(
                employee: employee,
                isSelected: _selectedEmployeeId == employee.id,
                onTap: () => _onEmployeeSelected(employee),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmployeeGridItem extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeGridItem({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Color.fromARGB(51, 33, 150, 243) : Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Color.fromARGB(128, 158, 158, 158),
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 48.0, color: Theme.of(context).primaryColor),
              SizedBox(height: 8.0),
              Text(
                employee.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
