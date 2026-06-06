import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/orders_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    OrdersScreen(),
    MenuScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.brown,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
        ],
      ),
    );
  }
}
