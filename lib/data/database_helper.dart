import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_name TEXT NOT NULL,
          total_amount REAL NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          item_name TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL
        )
      ''');
    }
  }

  // =========================
  // CATEGORY CRUD
  // =========================

  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories');
  }

  Future<int> updateCategory(String oldName, String newName) async {
    final db = await database;

    return db.update(
      'categories',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  Future<int> deleteCategory(String name) async {
    final db = await database;

    return db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // =========================
  // MENU ITEM CRUD
  // =========================

  Future<int> insertMenuItem({
    required String name,
    required double price,
    required String category,
  }) async {
    final db = await database;

    return db.insert('menu_items', {
      'name': name,
      'price': price,
      'category': category,
    });
  }

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await database;
    return db.query('menu_items');
  }

  Future<int> updateMenuItem({
    required String oldName,
    required String oldCategory,
    required String name,
    required double price,
    required String category,
  }) async {
    final db = await database;

    return db.update(
      'menu_items',
      {'name': name, 'price': price, 'category': category},
      where: 'name = ? AND category = ?',
      whereArgs: [oldName, oldCategory],
    );
  }

  Future<int> deleteMenuItem(String name, String category) async {
    final db = await database;

    return db.delete(
      'menu_items',
      where: 'name = ? AND category = ?',
      whereArgs: [name, category],
    );
  }

  // =========================
  // ORDERS
  // =========================

  Future<int> createOrder({
    required String customerName,
    required double totalAmount,
  }) async {
    final db = await database;

    return db.insert('orders', {
      'customer_name': customerName,
      'total_amount': totalAmount,
      'status': 'Pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> addOrderItem({
    required int orderId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    final db = await database;

    return db.insert('order_items', {
      'order_id': orderId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
    });
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    final db = await database;

    return db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;

    return db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<int> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final db = await database;

    return db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<Map<String, dynamic>?> getOrder(int orderId) async {
    final db = await database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> deleteOrderItems(int orderId) async {
    final db = await database;

    return db.delete(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updateOrder({
    required int orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    final db = await database;

    return db.update(
      'orders',
      {'customer_name': customerName, 'total_amount': totalAmount},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<double> getTotalRevenue() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT SUM(total_amount) as revenue
    FROM orders
    WHERE status = 'Served'
  ''');

    return (result.first["revenue"] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTotalOrders() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM orders
    WHERE status = 'Served'
  ''');

    return result.first["count"] as int;
  }

  Future<int> getCancelledOrders() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM orders
    WHERE status = 'Cancelled'
  ''');

    return result.first["count"] as int;
  }

  Future<double> getAverageOrderValue() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT AVG(total_amount) as average
    FROM orders
    WHERE status = 'Served'
  ''');

    return (result.first["average"] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, dynamic>?> getBestSellingItem() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT
      item_name,
      SUM(quantity) as total_sold
    FROM order_items
    GROUP BY item_name
    ORDER BY total_sold DESC
    LIMIT 1
  ''');

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTopItems() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      item_name,
      SUM(quantity) as total_sold
    FROM order_items
    GROUP BY item_name
    ORDER BY total_sold DESC
    LIMIT 5
  ''');
  }

  Future<double> getRevenue(String period) async {
    final db = await database;

    String whereClause = "status = 'Served'";

    if (period == "today") {
      whereClause += " AND date(created_at) = date('now','localtime')";
    } else if (period == "week") {
      whereClause +=
          " AND date(created_at) >= date('now','-7 days','localtime')";
    } else if (period == "month") {
      whereClause +=
          " AND date(created_at) >= date('now','-30 days','localtime')";
    }

    final result = await db.rawQuery('''
    SELECT SUM(total_amount) as revenue
    FROM orders
    WHERE $whereClause
  ''');

    return (result.first["revenue"] as num?)?.toDouble() ?? 0;
  }

  Future<int> getOrdersCount(String period) async {
    final db = await database;

    String whereClause = "status = 'Served'";

    if (period == "today") {
      whereClause += " AND date(created_at) = date('now','localtime')";
    } else if (period == "week") {
      whereClause +=
          " AND date(created_at) >= date('now','-7 days','localtime')";
    } else if (period == "month") {
      whereClause +=
          " AND date(created_at) >= date('now','-30 days','localtime')";
    }

    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM orders
    WHERE $whereClause
  ''');

    return result.first["count"] as int;
  }

  Future<int> getCancelledCount(String period) async {
    final db = await database;

    String whereClause = "status = 'Cancelled'";

    if (period == "today") {
      whereClause += " AND date(created_at) = date('now','localtime')";
    } else if (period == "week") {
      whereClause +=
          " AND date(created_at) >= date('now','-7 days','localtime')";
    } else if (period == "month") {
      whereClause +=
          " AND date(created_at) >= date('now','-30 days','localtime')";
    }

    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM orders
    WHERE $whereClause
  ''');

    return result.first["count"] as int;
  }

  Future<double> getAverageOrder(String period) async {
    final db = await database;

    String whereClause = "status = 'Served'";

    if (period == "today") {
      whereClause += " AND date(created_at) = date('now','localtime')";
    } else if (period == "week") {
      whereClause +=
          " AND date(created_at) >= date('now','-7 days','localtime')";
    } else if (period == "month") {
      whereClause +=
          " AND date(created_at) >= date('now','-30 days','localtime')";
    }

    final result = await db.rawQuery('''
    SELECT AVG(total_amount) as average
    FROM orders
    WHERE $whereClause
  ''');

    return (result.first["average"] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, dynamic>?> getPeakDay() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT
      strftime('%w', created_at) as day_number,
      SUM(total_amount) as revenue
    FROM orders
    WHERE status = 'Served'
    GROUP BY day_number
    ORDER BY revenue DESC
    LIMIT 1
  ''');

    if (result.isEmpty) return null;

    const days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    final row = result.first;

    return {
      "day": days[int.parse(row["day_number"].toString())],
      "revenue": row["revenue"],
    };
  }

  Future<Map<String, dynamic>?> getSlowestDay() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT
      strftime('%w', created_at) as day_number,
      SUM(total_amount) as revenue
    FROM orders
    WHERE status = 'Served'
    GROUP BY day_number
    ORDER BY revenue ASC
    LIMIT 1
  ''');

    if (result.isEmpty) return null;

    const days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    final row = result.first;

    return {
      "day": days[int.parse(row["day_number"].toString())],
      "revenue": row["revenue"],
    };
  }

  Future<Map<String, dynamic>?> getPeakHour() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT
      strftime('%H', created_at) as hour,
      COUNT(*) as orders_count
    FROM orders
    WHERE status = 'Served'
    GROUP BY hour
    ORDER BY orders_count DESC
    LIMIT 1
  ''');

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    final hour = int.parse(row["hour"].toString());

    String formatHour(int h) {
      if (h == 0) return "12 AM";
      if (h < 12) return "$h AM";
      if (h == 12) return "12 PM";
      return "${h - 12} PM";
    }

    return {
      "hour": "${formatHour(hour)} - ${formatHour((hour + 1) % 24)}",
      "orders": row["orders_count"],
    };
  }

  Future<List<Map<String, dynamic>>> getWeekdayDemandPattern() async {
    final db = await database;

    const days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < 7; i++) {
      final query = await db.rawQuery('''
      SELECT
        oi.item_name,
        SUM(oi.quantity) as total_sold
      FROM order_items oi
      JOIN orders o
        ON oi.order_id = o.id
      WHERE o.status = 'Served'
        AND strftime('%w', o.created_at) = '$i'
      GROUP BY oi.item_name
      ORDER BY total_sold DESC
      LIMIT 1
    ''');

      if (query.isNotEmpty) {
        result.add({
          "day": days[i],
          "item_name": query.first["item_name"],
          "total_sold": query.first["total_sold"],
        });
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getCategoryLeaders() async {
    final db = await database;

    final categories = await db.query('categories');

    List<Map<String, dynamic>> leaders = [];

    for (var category in categories) {
      final categoryName = category["name"] as String;

      if (categoryName == "Uncategorized") {
        continue;
      }

      final result = await db.rawQuery(
        '''
      SELECT
        oi.item_name,
        SUM(oi.quantity) as total_sold
      FROM order_items oi
      JOIN orders o
        ON oi.order_id = o.id
      JOIN menu_items mi
        ON mi.name = oi.item_name
      WHERE o.status = 'Served'
        AND mi.category = ?
      GROUP BY oi.item_name
      ORDER BY total_sold DESC
      LIMIT 1
    ''',
        [categoryName],
      );

      if (result.isNotEmpty) {
        leaders.add({
          "category": categoryName,
          "item_name": result.first["item_name"],
          "total_sold": result.first["total_sold"],
        });
      }
    }

    return leaders;
  }

  Future<List<Map<String, dynamic>>> getWorstSellingItems() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      item_name,
      SUM(quantity) as total_sold
    FROM order_items
    GROUP BY item_name
    ORDER BY total_sold ASC
    LIMIT 5
  ''');
  }

  Future<void> clearBusinessData() async {
    final db = await database;

    await db.delete('order_items');

    await db.delete('orders');
  }

  Future<Map<String, dynamic>> getBusinessDataStats() async {
    final db = await database;

    final ordersResult = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM orders
  ''');

    final revenueResult = await db.rawQuery('''
    SELECT SUM(total_amount) as revenue
    FROM orders
    WHERE status = 'Served'
  ''');

    return {
      "orders": ordersResult.first["count"] ?? 0,
      "revenue": revenueResult.first["revenue"] ?? 0,
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
