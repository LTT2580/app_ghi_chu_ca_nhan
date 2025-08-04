import 'package:flutter/widgets.dart';
import 'database_helper.dart';
import 'database_provider.dart';

class AppDatabase {
  static Future<void> initialize() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database; // Khởi tạo database
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  static DatabaseProvider get provider => DatabaseProvider();
}