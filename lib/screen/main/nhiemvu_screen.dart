import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../profile/taikhoan_screen.dart';
import 'trangchu_screen.dart';
import 'lichtrinh_screen.dart';
import 'tiendo_screen.dart';
import 'nhomviec_screen.dart';
import '../tasks/themnhiemvu_screen.dart';
import '../../data/database_provider.dart';

class NhiemVu extends StatefulWidget {
  const NhiemVu({super.key});

  @override
  State<NhiemVu> createState() => _NhiemVuState();
}

class _NhiemVuState extends State<NhiemVu> {
  int _selectedIndex = 4;
  int _menuSelectedIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  List<NhiemVuGroup> _taskGroups = [];
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
        setState(() => _currentUser = User.fromJson(json.decode(userJson)));
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải thông tin người dùng');
      print("Error loading user: $e");
    }
  }

  // Trong nhiemvu_screen.dart
Future<void> _loadData() async {
  try {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    
    // Load tasks trước
    final tasks = await dbProvider.getNhiemVuList();
    final Map<String, List<NhiemVuModel>> groupedTasks = {};
    
    for (var task in tasks) {
      final dateKey = DateFormat('yyyy-MM-dd').format(task.date);
      groupedTasks.putIfAbsent(dateKey, () => []).add(task);
    }
    
    setState(() {
      _taskGroups = groupedTasks.entries.map((entry) => NhiemVuGroup(
        date: DateTime.parse(entry.key),
        tasks: entry.value,
      )).toList();
      
      _taskGroups.sort((a, b) => a.date.compareTo(b.date));
      _isLoading = false;
    });
    
  } catch (e) {
    _showErrorSnackbar('Lỗi khi tải dữ liệu');
    setState(() => _isLoading = false);
  }
}

  Future<void> _addNewTask(NhiemVuModel newTask) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.insertNhiemVu(newTask);
    } catch (e) {
      _showErrorSnackbar('Lỗi khi thêm nhiệm vụ');
      print("Error adding new task: $e");
    }
  }

  Future<void> _toggleTaskStatus(NhiemVuModel task, bool isCompleted) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.toggleNhiemVuStatus(task.id, isCompleted);
    } catch (e) {
      _showErrorSnackbar('Lỗi khi cập nhật trạng thái');
      print("Error toggling task status: $e");
      setState(() => task.isCompleted = !isCompleted);
    }
  }

  Future<void> _deleteTask(NhiemVuModel task) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.deleteNhiemVu(task.id);
    } catch (e) {
      _showErrorSnackbar('Lỗi khi xóa nhiệm vụ');
      print("Error deleting task: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _taskGroups.isEmpty
              ? const Center(child: Text('Không có nhiệm vụ nào'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _taskGroups.length,
                        itemBuilder: (context, groupIndex) {
                          final group = _taskGroups[groupIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  group.formattedDate,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...group.tasks.map((task) => _buildTaskItem(task)).toList(),
                              if (groupIndex != _taskGroups.length - 1)
                                const Divider(height: 1, thickness: 1),
                            ],
                          );
                        },
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
                          final newTask = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThemNhiemVu(
                                availableGroups: _workGroups,
                                ngay: DateTime.now(),
                              ),
                            ),
                          );
                          if (newTask != null) _addNewTask(newTask);
                        },
                        child: const Text('Thêm nhiệm vụ'),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.name ?? 'Khách'),
            accountEmail: Text(_currentUser?.email ?? 'Chưa đăng nhập'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage(_currentUser?.avatar ?? 'assets/avatar.png'),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang chủ'),
            selected: _menuSelectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TrangchuWidget()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Thông tin'),
            selected: _menuSelectedIndex == 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaiKhoanScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.app_registration),
            title: const Text('Đăng ký'),
            selected: _menuSelectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Dangky()),
              );
            },
          ),
          const Divider(color: Colors.black),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Dangnhap()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Nhóm việc'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Lịch trình'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tiến độ'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Nhiệm vụ'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber[800],
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrangchuWidget()));
            break;
          case 1: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhomViecWidget()));
            break;
          case 2: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LichtrinhWidget()));
            break;
          case 3: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TienDoWidget()));
            break;
          case 4: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhiemVu()));
            break;
        }
      },
    );
  }

  Widget _buildTaskItem(NhiemVuModel task) {
    final group = _workGroups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => NhomViec(
        id: '',
        title: 'Không có nhóm',
        description: '',
        timeRange: '',
        tasks: [],
        color: '9E9E9E',
      ),
    );

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có chắc muốn xóa nhiệm vụ này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteTask(task),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: CheckboxListTile(
          title: Text(task.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.subtitle),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: group.colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${group.title} • ${task.formattedDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          value: task.isCompleted,
          onChanged: (bool? value) {
            if (value != null) {
              setState(() => task.isCompleted = value);
              _toggleTaskStatus(task, value);
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
          secondary: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Chỉnh sửa'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xóa'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                await _deleteTask(task);
              } else if (value == 'edit') {
                // TODO: Implement edit functionality
              }
            },
          ),
        ),
      ),
    );
  }
}