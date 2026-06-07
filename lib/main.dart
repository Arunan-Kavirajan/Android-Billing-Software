import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/orders_screen.dart';
import 'data/app_data.dart';
import 'data/database_helper.dart';

Future<void> preloadMenuData() async {
  final categories = await DatabaseHelper.instance.getCategories();
  final items = await DatabaseHelper.instance.getMenuItems();

  bool hasUncategorized = categories.any(
    (c) => c["name"] == AppData.uncategorized,
  );

  if (!hasUncategorized) {
    await DatabaseHelper.instance.insertCategory(AppData.uncategorized);
    categories.add({"name": AppData.uncategorized});
  }

  AppData.categories = categories.map((e) => e["name"] as String).toList();

  AppData.categories.remove(AppData.uncategorized);
  AppData.categories.add(AppData.uncategorized);

  AppData.menuItems = items;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await preloadMenuData();

  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'D Brownie Billing',
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF7F5F2),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4C41),
          primary: const Color(0xFF6D4C41),
          secondary: const Color(0xFFA1887F),
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF6D4C41),
          foregroundColor: Colors.white,
        ),

        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D4C41),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF6D4C41),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
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
