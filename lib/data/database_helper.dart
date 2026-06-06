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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
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
  }

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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
