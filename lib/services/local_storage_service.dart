import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _employeeIdKey = 'employee_id';

  Future<void> saveEmployeeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeIdKey, id);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }
}
