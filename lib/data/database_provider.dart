import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // User Management
  Future<int> insertUser(User user) async {
    final id = await _dbHelper.insertUser(user);
    notifyListeners();
    return id;
  }

  Future<User?> getUserByEmail(String email) async {
    return await _dbHelper.getUserByEmail(email);
  }

  Future<List<User>> getUsers() async {
    return await _dbHelper.getUsers();
  }

  Future<int> updateUser(User user) async {
    final result = await _dbHelper.updateUser(user);
    notifyListeners(); // Đảm bảo thông báo thay đổi
    return result;
  }

  Future<int> deleteUser(int id) async {
    final result = await _dbHelper.deleteUser(id);
    notifyListeners();
    return result;
  }

  // NhomViec Management
  Future<int> insertNhomViec(NhomViec nhomViec) async {
    final result = await _dbHelper.insertNhomViec(nhomViec);
    notifyListeners();
    return result;
  }

  Future<List<NhomViec>> getNhomViecList() async {
    return await _dbHelper.getNhomViecList();
  }

  Future<NhomViec?> getNhomViecById(String id) async {
    return await _dbHelper.getNhomViecById(id);
  }

  Future<int> updateNhomViec(NhomViec nhomViec) async {
    final result = await _dbHelper.updateNhomViec(nhomViec);
    notifyListeners(); // Đảm bảo thông báo thay đổi
    return result;
  }

  Future<int> deleteNhomViec(String id) async {
    final result = await _dbHelper.deleteNhomViec(id);
    notifyListeners();
    return result;
  }

  // NhiemVu Management
  Future<int> insertNhiemVu(NhiemVuModel nhiemVu) async {
    final result = await _dbHelper.insertNhiemVu(nhiemVu);
    notifyListeners();
    return result;
  }

  Future<List<NhiemVuModel>> getNhiemVuList() async {
    return await _dbHelper.getNhiemVuList();
  }

  Future<List<NhiemVuModel>> getNhiemVuByGroupId(String groupId) async {
    return await _dbHelper.getNhiemVuByGroupId(groupId);
  }

  Future<List<NhiemVuModel>> getNhiemVuByDate(DateTime date) async {
    return await _dbHelper.getNhiemVuByDate(date);
  }

  Future<int> updateNhiemVu(NhiemVuModel nhiemVu) async {
    final result = await _dbHelper.updateNhiemVu(nhiemVu);
    notifyListeners(); // Đảm bảo thông báo thay đổi
    return result;
  }

  Future<int> deleteNhiemVu(String id) async {
    final result = await _dbHelper.deleteNhiemVu(id);
    notifyListeners();
    return result;
  }

  Future<int> toggleNhiemVuStatus(String id, bool isCompleted) async {
    final result = await _dbHelper.toggleNhiemVuStatus(id, isCompleted);
    notifyListeners();
    return result;
  }

  // Statistics
  Future<Map<String, dynamic>> getCompletionStats() async {
    return await _dbHelper.getCompletionStats();
  }

  Future<List<Map<String, dynamic>>> getGroupStats() async {
    return await _dbHelper.getGroupStats();
  }
}