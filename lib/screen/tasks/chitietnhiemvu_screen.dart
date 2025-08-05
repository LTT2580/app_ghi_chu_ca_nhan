import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/screen/main/lichtrinh_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhomviec_screen.dart';
import 'package:cham_ly_thuyet/screen/main/tiendo_screen.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';
import 'package:cham_ly_thuyet/widgets/app_bottom_navigation.dart';
import 'package:cham_ly_thuyet/widgets/thanhmenu_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';

class ChiTietNhiemVuPage extends StatefulWidget {
  final NhiemVuModel nhiemVu;

  const ChiTietNhiemVuPage({Key? key, required this.nhiemVu}) : super(key: key);

  @override
  _ChiTietNhiemVuPageState createState() => _ChiTietNhiemVuPageState();
}

class _ChiTietNhiemVuPageState extends State<ChiTietNhiemVuPage> {
  late NhiemVuModel _currentNhiemVu;

  @override
  void initState() {
    super.initState();
    _currentNhiemVu = widget.nhiemVu;
  }

  Future<void> _toggleTaskStatus(bool? value) async {
    if (value == null) return;
    setState(() {
      _currentNhiemVu.isCompleted = value;
    });
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await dbProvider.toggleNhiemVuStatus(_currentNhiemVu.id, value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái thành công')),
      );
    } catch (e) {
      setState(() {
        _currentNhiemVu.isCompleted = !value; // Revert on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa nhiệm vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
        await dbProvider.deleteNhiemVu(_currentNhiemVu.id);
        Navigator.pop(context, true); // Trở về và báo đã xóa
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiết nhiệm vụ'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // TODO: Mở màn hình chỉnh sửa
          },
        ),
      ],
    ),
    drawer: UnifiedDrawer(
      selectedIndex: -1, // Không chọn mục nào
      currentUser: null, // Thay bằng user thực tế nếu có
      onMenuSelected: (index) => _navigateToMainScreen(index),
    ),
    bottomNavigationBar: AppBottomNavigation(
      currentIndex: -1, // Không chọn mục nào
      onTap: (index) => _navigateToMainScreen(index),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _currentNhiemVu.isCompleted,
                onChanged: _toggleTaskStatus,
              ),
              Expanded(
                child: Text(
                  _currentNhiemVu.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    decoration: _currentNhiemVu.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentNhiemVu.subtitle,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.calendar_today, 'Ngày:', _currentNhiemVu.formattedDate),
          _buildInfoRow(Icons.access_time, 'Thời gian:', 
              '${_currentNhiemVu.startTime.format(context)} - ${_currentNhiemVu.endTime.format(context)}'),
          _buildInfoRow(Icons.timer, 'Thời lượng:', 
              '${_currentNhiemVu.duration.inHours} giờ ${_currentNhiemVu.duration.inMinutes.remainder(60)} phút'),
          const SizedBox(height: 32),
          if (_currentNhiemVu.groupId != null) ...[
            const Text(
              'Thuộc nhóm công việc:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Nhóm công việc ${_currentNhiemVu.groupId}'),
            ),
          ],
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _deleteTask,
      child: const Icon(Icons.delete),
      backgroundColor: Colors.red,
    ),
  );
}

// Thêm hàm điều hướng mới
void _navigateToMainScreen(int index) {
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}