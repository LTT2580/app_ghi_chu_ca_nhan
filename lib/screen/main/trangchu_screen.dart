import 'package:cham_ly_thuyet/data/database_helper.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:cham_ly_thuyet/screen/main/lichtrinh_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhomviec_screen.dart';
import 'package:cham_ly_thuyet/screen/main/thongbao_screen.dart';
import 'package:cham_ly_thuyet/screen/main/tiendo_screen.dart';
import 'package:cham_ly_thuyet/screen/tasks/chitietnhomviec_screen.dart';
import 'package:cham_ly_thuyet/widgets/The_nhom_viec.dart';
import 'package:cham_ly_thuyet/widgets/thanhmenu_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class TrangchuWidget extends StatefulWidget {
  @override
  _TrangchuWidgetState createState() => _TrangchuWidgetState();
}

class _TrangchuWidgetState extends State<TrangchuWidget> {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  List<NhomViec> _workGroups = [];
  List<NhiemVuModel> _todayTasks = [];
  List<NhiemVuModel> _allTasks = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late DatabaseProvider _databaseProvider;

  @override
  void initState() {
    super.initState();
    _databaseProvider = DatabaseProvider();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser != null) {
      _loadData();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('currentUser');
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        setState(() {
          _currentUser = User.fromJson(userData);
        });
        // Load data after user is loaded
        await _loadData();
      } else {
        // Redirect to login if no user found
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dangnhap()),
          );
        });
      }
    } catch (e) {
      print("Error loading user: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load work groups
      final allWorkGroups = await _databaseProvider.getNhomViecList();
      
      // Filter work groups for current user if needed
      final userWorkGroups = allWorkGroups.where((group) {
        return group.userId == null || group.userId == _currentUser!.id.toString();
      }).toList();

      // Load today's tasks
      final today = DateTime.now();
      final todayTasks = await _databaseProvider.getNhiemVuByDate(today);
      
      // Load all tasks for current user
      final allTasks = await _databaseProvider.getNhiemVuList();
      final userTasks = allTasks.where((task) {
        return task.userId == null || task.userId == _currentUser!.id.toString();
      }).toList();

      setState(() {
        _workGroups = userWorkGroups;
        _todayTasks = todayTasks.where((task) {
          return task.userId == null || task.userId == _currentUser!.id.toString();
        }).toList();
        _allTasks = userTasks;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        _isLoading = false;
      });
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Lỗi tải dữ liệu'),
            content: Text('Có lỗi xảy ra khi tải dữ liệu. Vui lòng thử lại.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Retry
                },
                child: Text('Thử lại'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Dangnhap()),
        (route) => false,
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  Future<void> _toggleTaskStatus(NhiemVuModel task, bool value) async {
    try {
      await _databaseProvider.toggleNhiemVuStatus(task.id, value);
      
      setState(() {
        task.isCompleted = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Đã hoàn thành nhiệm vụ' : 'Đã bỏ hoàn thành nhiệm vụ'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print("Error toggling task status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi cập nhật trạng thái'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(NhiemVuModel task) async {
    try {
      await _databaseProvider.deleteNhiemVu(task.id);
      
      setState(() {
        _todayTasks.removeWhere((t) => t.id == task.id);
        _allTasks.removeWhere((t) => t.id == task.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa nhiệm vụ'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi xóa nhiệm vụ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 Widget _buildWorkGroupCard(NhomViec group) {
  return WorkGroupCard(
    nhomViec: group,
    isCompactView: true,
    onTaskToggle: (task, value) {
      _toggleTaskStatus(task, value);
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isCompleted ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted ? Colors.green[200]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskStatus(task, !task.isCompleted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: task.isCompleted ? Colors.green[700] : Colors.grey[800],
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${group.color}')),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        task.formattedTimeRange(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final completedTasks = _todayTasks.where((task) => task.isCompleted).length;
    final totalTasks = _todayTasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$completedTasks/$totalTasks nhiệm vụ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CircularProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 6,
          ),
          SizedBox(width: 8),
          Text(
            '${(completionRate * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              "Xin chào ${_currentUser?.name ?? 'Khách'}!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Hôm nay là ${DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now())}",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 20),

            // Stats card
            _buildStatsCard(),
            SizedBox(height: 24),

            // Work groups section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nhóm việc cần làm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_workGroups.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NhomViecWidget()),
                      );
                    },
                    child: Text('Xem tất cả'),
                  ),
              ],
            ),
            SizedBox(height: 12),

            _workGroups.isEmpty
                ? Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_off, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có nhóm việc nào',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _workGroups.length,
                      itemBuilder: (context, index) {
                        return _buildWorkGroupCard(_workGroups[index]);
                      },
                    ),
                  ),

            SizedBox(height: 24),

            // Today's tasks section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nhiệm vụ hôm nay",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_todayTasks.length > 5)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NhiemVu()),
                      );
                    },
                    child: Text('Xem tất cả'),
                  ),
              ],
            ),
            SizedBox(height: 12),

            _todayTasks.isEmpty
                ? Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'Không có nhiệm vụ nào hôm nay',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _todayTasks.take(5).map((task) => _buildTaskItem(task)).toList(),
                  ),

            if (_todayTasks.length > 5) ...[
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NhiemVu()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    elevation: 0,
                  ),
                  child: Text("Xem tất cả nhiệm vụ"),
                ),
              ),
            ],

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Chủ"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
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
          selectedIndex: 0, // Index cho trang chủ
          currentUser: _currentUser,
          onMenuSelected: (index) {
    // Xử lý khi chọn menu nếu cần
          print('Selected menu index: $index');
        },
      ),
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Nhóm việc'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Lịch trình'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tiến độ'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Nhiệm vụ'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NhomViecWidget()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LichtrinhScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TienDoWidget()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NhiemVu()),
              );
              break;
          }
        },
      ),
    );
  }
}