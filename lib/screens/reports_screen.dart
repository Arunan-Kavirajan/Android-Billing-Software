import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), centerTitle: true),
      body: const Center(
        child: Text("Reports Coming Soon", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
