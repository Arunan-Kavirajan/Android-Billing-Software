import 'package:flutter/material.dart';
import 'data/database_helper.dart';

class TestDBScreen extends StatefulWidget {
  const TestDBScreen({super.key});

  @override
  State<TestDBScreen> createState() => _TestDBScreenState();
}

class _TestDBScreenState extends State<TestDBScreen> {
  String status = "Not Tested";

  Future<void> testDatabase() async {
    try {
      await DatabaseHelper.instance.database;

      setState(() {
        status = "Database Created Successfully";
      });
    } catch (e) {
      setState(() {
        status = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Database Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: testDatabase,
              child: const Text("Test Database"),
            ),
          ],
        ),
      ),
    );
  }
}
