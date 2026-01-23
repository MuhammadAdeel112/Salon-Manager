import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title, value;
  final Color color;

  StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color)
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}