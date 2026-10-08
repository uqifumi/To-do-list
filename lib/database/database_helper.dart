import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        description TEXT,
        isDone      INTEGER NOT NULL DEFAULT 0,
        createdAt   TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0',
      );
    }
  }

  // CREATE
  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ — seluruh tugas
  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // READ — satu tugas berdasarkan id
  Future<Todo?> getTodoById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  // UPDATE — seluruh kolom tugas
  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // UPDATE — status selesai/belum selesai
  Future<int> toggleTodoStatus(int id, bool isDone) async {
    final db = await database;
    return await db.update(
      'todos',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE — satu tugas
  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE — semua tugas yang sudah selesai
  Future<int> deleteCompletedTodos() async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'isDone = ?',
      whereArgs: [1],
    );
  }
}
