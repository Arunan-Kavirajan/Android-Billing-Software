import 'package:flutter/material.dart';

void main() {
  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'D Brownie Billing',
      home: Scaffold(
        appBar: AppBar(title: const Text('D Brownie Billing')),
        body: const Center(child: Text('Billing Screen')),
      ),
    );
  }
}
