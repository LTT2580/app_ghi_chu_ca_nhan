// nhomviec_screen.dart
import 'package:cham_ly_thuyet/screen/main/thongbao_screen.dart';
import 'package:cham_ly_thuyet/widgets/The_nhom_viec.dart';
import 'package:cham_ly_thuyet/widgets/app_bottom_navigation.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/main/lichtrinh_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/main/tiendo_screen.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';
import 'package:cham_ly_thuyet/screen/tasks/chitietnhomviec_screen.dart'; // Import trang chi tiết
import 'package:cham_ly_thuyet/screen/tasks/themnhomviec_screen.dart';
import 'package:cham_ly_thuyet/widgets/thanhmenu_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NhomViecWidget extends StatefulWidget {
  const NhomViecWidget({super.key});

  @override
  State<NhomViecWidget> createState() => _NhomViecWidgetState();
}

class _NhomViecWidgetState extends State<NhomViecWidget> {
  int _selectedIndex = 1;
  User? _currentUser;
  bool _isLoading = true;
  List<NhomViec> _workGroups = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('currentUser');
      
      if (userJson != null) {
        setState(() {
          _currentUser = User.fromJson(json.decode(userJson));
        });
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải thông tin người dùng');
      print("Error loading user: $e");
    }
  }

  // Tải danh sách nhóm việc từ database
  Future<void> _loadData() async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final workGroups = await dbProvider.getNhomViecList();
      
      setState(() {
        _workGroups = workGroups;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải danh sách nhóm việc');
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  // Thêm nhóm việc mới
  Future<void> _addNewGroup(NhomViec newGroup) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.insertNhomViec(newGroup);
      await _loadData(); // Tải lại dữ liệu sau khi thêm
    } catch (e) {
      _showErrorSnackbar('Lỗi khi thêm nhóm việc');
      print("Error adding new group: $e");
    }
  }

  // Xóa nhóm việc
  Future<void> _deleteGroup(String groupId) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.deleteNhomViec(groupId);
      await _loadData(); // Tải lại dữ liệu sau khi xóa
    } catch (e) {
      _showErrorSnackbar('Lỗi khi xóa nhóm việc');
      print("Error deleting group: $e");
    }
  }

  // Chuyển đổi trạng thái nhiệm vụ
  Future<void> _toggleTaskStatus(NhiemVuModel task, bool isCompleted) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.toggleNhiemVuStatus(task.id, isCompleted);
    } catch (e) {
      _showErrorSnackbar('Lỗi khi cập nhật trạng thái nhiệm vụ');
      print("Error toggling task status: $e");
      setState(() => task.isCompleted = !isCompleted);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Xử lý chọn item bottom nav
  void _handleBottomNavSelection(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrangchuWidget()));
        break;
      case 1: 
        break;
      case 2: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LichtrinhScreen()));
        break;
      case 3: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TienDoWidget()));
        break;
      case 4: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhiemVu()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm việc'),
                    actions: [
              IconButton(
            icon: Image.asset('assets/icon/bell.png',width: 24, height: 24,), // Đường dẫn đến icon chuông
            onPressed: () {
              // Chuyển đến trang khác khi nhấn vào icon chuông
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
            ],
      ),
      drawer: UnifiedDrawer(
          selectedIndex: 0,
          currentUser: _currentUser,
          onMenuSelected: (index) {
            print('Selected menu index: $index');
          },
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _workGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Không có nhóm việc nào'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Chuyển đến trang thêm nhóm việc
                          final newGroup = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ThemNhomViecScreen()),
                          );
                          if (newGroup != null && newGroup is NhomViec) {
                            await _addNewGroup(newGroup);
                          }
                        },
                        child: const Text('Thêm nhóm việc'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _workGroups.length,
                        itemBuilder: (context, index) => _buildNhomViecCard(_workGroups[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final newGroup = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ThemNhomViecScreen()),
                          );
                          if (newGroup != null && newGroup is NhomViec) {
                            await _addNewGroup(newGroup);
                          }
                        },
                        child: const Text('Thêm nhóm việc'),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _handleBottomNavSelection,
      ),
    );
  }

  // Widget hiển thị card nhóm việc
  Widget _buildNhomViecCard(NhomViec nhomViec) {
    return FutureBuilder<List<NhiemVuModel>>(
      future: Provider.of<DatabaseProvider>(context, listen: false)
          .getNhiemVuByGroupId(nhomViec.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final tasks = snapshot.data ?? [];
          return InkWell(
            onTap: () {
              // Chuyển đến trang chi tiết nhóm việc khi nhấn vào card
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChitietnhomviecWidget(group: nhomViec.copyWith(tasks: tasks)),
                ),
              );
            },
            child: WorkGroupCard(
              key: Key(nhomViec.id),
              nhomViec: nhomViec.copyWith(tasks: tasks),
              isCompactView: false,
              showDeleteOption: true,
              onDelete: (groupId) => _deleteGroup(groupId),
              onTaskToggle: (task, value) => _toggleTaskStatus(task, value),
            ),
          );
        } else {
          return const Center(child: Text('Không có nhiệm vụ nào.'));
        }
      },
    );
  }
}