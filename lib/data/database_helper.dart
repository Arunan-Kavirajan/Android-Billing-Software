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
    required String name,
    required double price,
    required String category,
  }) async {
    final db = await database;

    return db.update(
      'menu_items',
      {'name': name, 'price': price, 'category': category},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  Future<int> deleteMenuItem(String name) async {
    final db = await database;

    return db.delete('menu_items', where: 'name = ?', whereArgs: [name]);
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
