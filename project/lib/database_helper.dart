import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Mobil platformlar için standart veritabanı yolu
    String path = join(await getDatabasesPath(), 'customer_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, debt REAL, dueDate TEXT, phoneNumber TEXT)',
        );
      },
    );
  }

  // Müşteri ekleme
  Future<int> insertCustomer(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('customers', row);
  }

  // Tüm müşterileri sorgulama
  Future<List<Map<String, dynamic>>> queryAllCustomers() async {
    Database db = await database;
    return await db.query('customers');
  }

  // Müşteri güncelleme
  Future<int> updateCustomer(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update(
      'customers',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Müşteri silme
  Future<int> deleteCustomer(int id) async {
    Database db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
