import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'study_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY,
        documentId TEXT,
        question TEXT,
        answer TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY,
        documentId TEXT,
        question TEXT,
        options TEXT,
        correctAnswer INTEGER
      )
    ''');
  }

  Future<void> saveFlashcards(String documentId, List<Map<String, dynamic>> flashcards) async {
    final db = await database;
    for (var card in flashcards) {
      await db.insert('flashcards', {
        'documentId': documentId,
        'question': card['question'],
        'answer': card['answer'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getFlashcards(String documentId) async {
    final db = await database;
    return await db.query('flashcards', where: 'documentId = ?', whereArgs: [documentId]);
  }

  Future<void> saveQuizzes(String documentId, List<Map<String, dynamic>> quizzes) async {
    final db = await database;
    for (var quiz in quizzes) {
      await db.insert('quizzes', {
        'documentId': documentId,
        'question': quiz['question'],
        'options': quiz['options'].join(','),
        'correctAnswer': quiz['correctAnswer'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getQuizzes(String documentId) async {
    final db = await database;
    return await db.query('quizzes', where: 'documentId = ?', whereArgs: [documentId]);
  }
}
