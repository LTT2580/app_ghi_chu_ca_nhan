import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/screen/tasks/chitietnhiemvu_screen.dart';
import 'package:cham_ly_thuyet/widgets/app_bottom_navigation.dart';
import 'package:cham_ly_thuyet/widgets/thanhmenu_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/database_provider.dart';
import '../main/trangchu_screen.dart';
import '../main/nhomviec_screen.dart';
import '../main/tiendo_screen.dart';
import '../main/nhiemvu_screen.dart';
import '../main/lichtrinh_screen.dart';

class ChitietnhomviecWidget extends StatefulWidget {
  final NhomViec group;
  const ChitietnhomviecWidget({super.key, required this.group});

  @override
  _ChitietnhomviecWidgetState createState() => _ChitietnhomviecWidgetState();
}

class _ChitietnhomviecWidgetState extends State<ChitietnhomviecWidget> {
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final updatedGroup = await dbProvider.getNhomViecById(widget.group.id);
      if (updatedGroup != null) {
        setState(() {
          widget.group.tasks = updatedGroup.tasks;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải nhiệm vụ');
      print("Error loading tasks: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get completedCount {
    return widget.group.tasks.where((task) => task.isCompleted).length;
  }

  double get completionPercentage {
    if (widget.group.tasks.isEmpty) return 0.0;
    return completedCount / widget.group.tasks.length;
  }

  Future<void> _toggleTaskStatus(NhiemVuModel task, bool isCompleted) async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.toggleNhiemVuStatus(task.id, isCompleted);
      await _loadTasks();
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
      await _loadTasks();
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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }
    void _navigateToMainScreen(int index) {
    Navigator.pop(context); // Đóng màn hình chi tiết hiện tại
    
    // Chuyển đến màn hình chính tương ứng
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TrangchuWidget()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NhomViecWidget()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LichtrinhScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TienDoWidget()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NhiemVu()),
        );
        break;
    }
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: Colors.white,
    drawer: UnifiedDrawer(
      selectedIndex: -1, // Không chọn mục nào
      currentUser: null, // Thay bằng user thực tế nếu có
      onMenuSelected: (index) => _navigateToMainScreen(index),
    ),
    bottomNavigationBar: AppBottomNavigation(
      currentIndex: -1, // Không chọn mục nào
      onTap: (index) => _navigateToMainScreen(index),
    ),
    body: SafeArea(    
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.group.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTasks,
                ),
              ],
            ),
          ),

          // Group info card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.group.colorValue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.group.timeRange,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.group.title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "${(completionPercentage * 100).toStringAsFixed(0)}% hoàn thành",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // Tasks list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nhiệm vụ",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                Text(
                  "$completedCount/${widget.group.tasks.length}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // Tasks list
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.group.tasks.isEmpty
                  ? Center(
                      child: Text('Không có nhiệm vụ nào',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.group.tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskItem(widget.group.tasks[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    ),
  );
}

  

   Widget _buildTaskItem(NhiemVuModel task) {
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
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChiTietNhiemVuPage(nhiemVu: task),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                if (value != null) {
                  setState(() => task.isCompleted = value);
                  _toggleTaskStatus(task, value);
                }
              },
              activeColor: widget.group.colorValue,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: task.isCompleted ? Colors.grey : Colors.grey[800],
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              task.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: task.isCompleted ? Colors.grey : null,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(task.startTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}