import 'dart:async';
import 'dart:io';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'; // Thêm package này

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal() {
    _initializeDatabaseFactory();
  }

  void _initializeDatabaseFactory() {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        if (kDebugMode) {
          debugPrint('Đã khởi tạo SQLite FFI cho desktop');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Lỗi khi khởi tạo database factory: $e');
      }
    }
  }

  // Thêm vào class DatabaseHelper trong database_helper.dart
  Future<User?> getUserById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return User.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by id: $e');
      return null;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('nhiem_vu');
      await db.delete('nhom_viec');
      await db.delete('users');
      if (kDebugMode) {
        debugPrint('All data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing data: $e');
      }
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      // Xác định đường dẫn database
      String dbPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDir.path, 'task_manager.db');
      } else {
        final path = await getDatabasesPath();
        dbPath = join(path, 'task_manager.db');
      }
      
      await deleteDatabase(dbPath);
      _database = null;
      await _initDatabase();
      if (kDebugMode) {
        debugPrint('Database reset successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting database: $e');
      }
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String dbPath;
      
      // XỬ LÝ ĐƯỜNG DẪN CHO DESKTOP
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDir.path, 'task_manager.db');
      } else {
        dbPath = join(await getDatabasesPath(), 'task_manager.db');
      }
      
      if (kDebugMode) {
        debugPrint('Database path: $dbPath');
      }
      
      return await openDatabase(
        dbPath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Database init error: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT UNIQUE,
          matkhau TEXT,
          avatar TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE nhom_viec (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          time_range TEXT,
          user_id INTEGER,
          color TEXT,
          parent_group_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE nhiem_vu (
          id TEXT PRIMARY KEY,
          title TEXT,
          subtitle TEXT,
          date TEXT,
          start_time TEXT,
          end_time TEXT,
          is_completed INTEGER,
          user_id INTEGER,
          group_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (group_id) REFERENCES nhom_viec (id)
        )
      ''');
      
      if (kDebugMode) {
        debugPrint('Database tables created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating tables: $e');
      }
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      if (kDebugMode) {
        debugPrint('Database upgraded from version $oldVersion to $newVersion');
      }
    }
  }

  // ========== User CRUD ==========
  Future<int> insertUser(User user) async {
    try {
      final db = await database;
      return await db.insert('users', user.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting user: $e');
      }
      rethrow;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return maps.isNotEmpty ? User.fromJson(maps.first) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user by email: $e');
      }
      return null;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('users');
      return List.generate(maps.length, (i) => User.fromJson(maps[i]));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting users: $e');
      }
      return [];
    }
  }

  Future<int> updateUser(User user) async {
    try {
      final db = await database;
      return await db.update(
        'users',
        user.toJson(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user: $e');
      }
      return 0;
    }
  }

  Future<int> deleteUser(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting user: $e');
      }
      return 0;
    }
  }

  // ========== NhomViec CRUD ==========
  Future<int> insertNhomViec(NhomViec nhomViec) async {
    try {
      final db = await database;
      return await db.insert('nhom_viec', {
        'id': nhomViec.id,
        'title': nhomViec.title,
        'description': nhomViec.description,
        'time_range': nhomViec.timeRange,
        'user_id': nhomViec.userId,
        'color': nhomViec.color,
        'parent_group_id': nhomViec.parentGroupId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting nhom viec: $e');
      }
      return 0;
    }
  }

// Trong database_helper.dart
// Trong hàm getNhomViecList
Future<List<NhomViec>> getNhomViecList() async {
  try {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('nhom_viec');
    
    return maps.map((map) => NhomViec.fromMap(map)).toList();
  } catch (e) {
    debugPrint('Error getting nhom viec list: $e');
    return [];
  }
}
  Future<NhomViec?> getNhomViecById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'nhom_viec',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        final tasks = await getNhiemVuByGroupId(id);
        return NhomViec(
          id: maps.first['id'],
          title: maps.first['title'],
          description: maps.first['description'],
          timeRange: maps.first['time_range'],
          tasks: tasks,
          userId: maps.first['user_id']?.toString(),
          color: maps.first['color'],
          parentGroupId: maps.first['parent_group_id'],
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting nhom viec by id: $e');
      }
      return null;
    }
  }

  Future<int> updateNhomViec(NhomViec nhomViec) async {
    try {
      final db = await database;
      return await db.update(
        'nhom_viec',
        {
          'title': nhomViec.title,
          'description': nhomViec.description,
          'time_range': nhomViec.timeRange,
          'color': nhomViec.color,
          'parent_group_id': nhomViec.parentGroupId,
        },
        where: 'id = ?',
        whereArgs: [nhomViec.id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating nhom viec: $e');
      }
      return 0;
    }
  }

  Future<int> deleteNhomViec(String id) async {
    try {
      final db = await database;
      await db.delete(
        'nhiem_vu',
        where: 'group_id = ?',
        whereArgs: [id],
      );
      return await db.delete(
        'nhom_viec',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting nhom viec: $e');
      }
      return 0;
    }
  }

  // ========== NhiemVu CRUD ==========
  Future<int> insertNhiemVu(NhiemVuModel nhiemVu) async {
    try {
      final db = await database;
      return await db.insert('nhiem_vu', {
        'id': nhiemVu.id,
        'title': nhiemVu.title,
        'subtitle': nhiemVu.subtitle,
        'date': DateFormat('yyyy-MM-dd').format(nhiemVu.date),
        'start_time': '${nhiemVu.startTime.hour.toString().padLeft(2, '0')}:${nhiemVu.startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${nhiemVu.endTime.hour.toString().padLeft(2, '0')}:${nhiemVu.endTime.minute.toString().padLeft(2, '0')}',
        'is_completed': nhiemVu.isCompleted ? 1 : 0,
        'user_id': nhiemVu.userId,
        'group_id': nhiemVu.groupId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inserting nhiem vu: $e');
      }
      return 0;
    }
  }

  Future<List<NhiemVuModel>> getNhiemVuList() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('nhiem_vu');
      return maps.map((map) => _nhiemVuFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting nhiem vu list: $e');
      }
      return [];
    }
  }

  Future<List<NhiemVuModel>> getNhiemVuByGroupId(String groupId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'nhiem_vu',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      return maps.map((map) => _nhiemVuFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting nhiem vu by group: $e');
      }
      return [];
    }
  }

  Future<List<NhiemVuModel>> getNhiemVuByDate(DateTime date) async {
    try {
      final db = await database;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final List<Map<String, dynamic>> maps = await db.query(
        'nhiem_vu',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      return maps.map((map) => _nhiemVuFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting nhiem vu by date: $e');
      }
      return [];
    }
  }

  Future<int> updateNhiemVu(NhiemVuModel nhiemVu) async {
    try {
      final db = await database;
      return await db.update(
        'nhiem_vu',
        {
          'title': nhiemVu.title,
          'subtitle': nhiemVu.subtitle,
          'date': DateFormat('yyyy-MM-dd').format(nhiemVu.date),
          'start_time': '${nhiemVu.startTime.hour.toString().padLeft(2, '0')}:${nhiemVu.startTime.minute.toString().padLeft(2, '0')}',
          'end_time': '${nhiemVu.endTime.hour.toString().padLeft(2, '0')}:${nhiemVu.endTime.minute.toString().padLeft(2, '0')}',
          'is_completed': nhiemVu.isCompleted ? 1 : 0,
          'group_id': nhiemVu.groupId,
        },
        where: 'id = ?',
        whereArgs: [nhiemVu.id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating nhiem vu: $e');
      }
      return 0;
    }
  }

  Future<int> deleteNhiemVu(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'nhiem_vu',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting nhiem vu: $e');
      }
      return 0;
    }
  }

  Future<int> toggleNhiemVuStatus(String id, bool isCompleted) async {
    try {
      final db = await database;
      return await db.update(
        'nhiem_vu',
        {'is_completed': isCompleted ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error toggling nhiem vu status: $e');
      }
      return 0;
    }
  }

  // Trong hàm _nhiemVuFromMap
  NhiemVuModel _nhiemVuFromMap(Map<String, dynamic> map) {
    // Sửa lỗi null safety
    final startTimeStr = map['start_time']?.toString() ?? '00:00';
    final endTimeStr = map['end_time']?.toString() ?? '23:59';
    
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    
    return NhiemVuModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      date: DateFormat('yyyy-MM-dd').parse(map['date']?.toString() ?? '1970-01-01'),
      startTime: TimeOfDay(
        hour: int.tryParse(startParts[0]) ?? 0,
        minute: int.tryParse(startParts[1]) ?? 0,
      ),
      endTime: TimeOfDay(
        hour: int.tryParse(endParts[0]) ?? 23,
        minute: int.tryParse(endParts[1]) ?? 59,
      ),
      isCompleted: map['is_completed'] == 1,
      userId: map['user_id']?.toString(),
      groupId: map['group_id']?.toString(),
    );
  }

  // ========== Statistics ==========
  Future<Map<String, dynamic>> getCompletionStats() async {
    try {
      final db = await database;
      
      final totalTasks = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM nhiem_vu')
      ) ?? 0;
      
      final completedTasks = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM nhiem_vu WHERE is_completed = 1')
      ) ?? 0;
      
      final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0;
      
      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'completionRate': completionRate,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting completion stats: $e');
      }
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'completionRate': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getGroupStats() async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT 
          nhom_viec.id, 
          nhom_viec.title, 
          COUNT(nhiem_vu.id) as total_tasks,
          SUM(CASE WHEN nhiem_vu.is_completed = 1 THEN 1 ELSE 0 END) as completed_tasks
        FROM nhom_viec
        LEFT JOIN nhiem_vu ON nhom_viec.id = nhiem_vu.group_id
        GROUP BY nhom_viec.id
      ''');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting group stats: $e');
      }
      return [];
    }
  }
    Future<NhiemVuModel?> getNhiemVuById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'nhiem_vu',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return _nhiemVuFromMap(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting nhiem vu by id: $e');
      }
      return null;
    }
  }
}