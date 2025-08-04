

import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';

import 'database_helper.dart';


class Repository {
  final DatabaseHelper _dbHelper;

  Repository(this._dbHelper);

  // User Repository
  Future<int> createUser(User user) => _dbHelper.insertUser(user);
  Future<User?> getUserByEmail(String email) => _dbHelper.getUserByEmail(email);
  Future<List<User>> getAllUsers() => _dbHelper.getUsers();
  Future<int> updateUser(User user) => _dbHelper.updateUser(user);
  Future<int> deleteUser(int id) => _dbHelper.deleteUser(id);

  // NhomViec Repository
  Future<int> createNhomViec(NhomViec nhomViec) => _dbHelper.insertNhomViec(nhomViec);
  Future<List<NhomViec>> getAllNhomViec() => _dbHelper.getNhomViecList();
  Future<NhomViec?> getNhomViecById(String id) => _dbHelper.getNhomViecById(id);
  Future<int> updateNhomViec(NhomViec nhomViec) => _dbHelper.updateNhomViec(nhomViec);
  Future<int> deleteNhomViec(String id) => _dbHelper.deleteNhomViec(id);

  // NhiemVu Repository
  Future<int> createNhiemVu(NhiemVuModel nhiemVu) => _dbHelper.insertNhiemVu(nhiemVu);
  Future<List<NhiemVuModel>> getAllNhiemVu() => _dbHelper.getNhiemVuList();
  Future<List<NhiemVuModel>> getNhiemVuByGroup(String groupId) => _dbHelper.getNhiemVuByGroupId(groupId);
  Future<List<NhiemVuModel>> getNhiemVuByDate(DateTime date) => _dbHelper.getNhiemVuByDate(date);
  Future<int> updateNhiemVu(NhiemVuModel nhiemVu) => _dbHelper.updateNhiemVu(nhiemVu);
  Future<int> deleteNhiemVu(String id) => _dbHelper.deleteNhiemVu(id);
  Future<int> toggleNhiemVuStatus(String id, bool isCompleted) => _dbHelper.toggleNhiemVuStatus(id, isCompleted);

  // Statistics Repository
  Future<Map<String, dynamic>> getCompletionStatistics() => _dbHelper.getCompletionStats();
  Future<List<Map<String, dynamic>>> getGroupStatistics() => _dbHelper.getGroupStats();
}