class AppData {
  static const String uncategorized = "Uncategorized";

  static List<String> categories = [
    uncategorized,
    "Brownies",
    "Waffles",
    "Beverages",
  ];

  static List<Map<String, dynamic>> menuItems = [
    {"name": "Classic Brownie", "price": 80.0, "category": "Brownies"},
    {"name": "Lotus Brownie", "price": 100.0, "category": "Brownies"},
    {"name": "Tea", "price": 15.0, "category": "Beverages"},
  ];
}
