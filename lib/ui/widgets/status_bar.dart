import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final String employeeName;
  final int productionCount;

  const StatusBar({
    super.key,
    required this.employeeName,
    required this.productionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Color.fromARGB(25, 33, 150, 243),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Employee: $employeeName',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Today\'s Records: $productionCount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
