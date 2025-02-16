import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'pos.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            unitPrice REAL NOT NULL,
            wholesalePrice REAL NOT NULL,
            barcode TEXT NOT NULL UNIQUE
          )
        ''');
      },
      version: 1,
    );
  }

  // Create
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert(
      'products', 
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read All
  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        unitPrice: maps[i]['unitPrice'],
        wholesalePrice: maps[i]['wholesalePrice'],
        barcode: maps[i]['barcode'],
      );
    });
  }

  // Read Single
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    return result.isNotEmpty ? Product.fromMap(result.first) : null;
  }

  // Update
  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Delete
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}