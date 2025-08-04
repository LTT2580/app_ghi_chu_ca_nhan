import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChiTietNhiemVuPage extends StatelessWidget {
  final NhiemVuModel nhiemVu;

  const ChiTietNhiemVuPage({Key? key, required this.nhiemVu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết nhiệm vụ'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Xử lý chỉnh sửa nhiệm vụ
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: nhiemVu.isCompleted,
                  onChanged: (value) {
                    // Xử lý cập nhật trạng thái hoàn thành
                  },
                ),
                Expanded(
                  child: Text(
                    nhiemVu.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: nhiemVu.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              nhiemVu.subtitle,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Ngày:', nhiemVu.formattedDate),
            _buildInfoRow(Icons.access_time, 'Thời gian:', 
                nhiemVu.formattedTimeRange(context)),
            _buildInfoRow(Icons.timer, 'Thời lượng:', 
                '${nhiemVu.duration.inHours} giờ ${nhiemVu.duration.inMinutes.remainder(60)} phút'),
            SizedBox(height: 32),
            if (nhiemVu.groupId != null) ...[
              Text(
                'Thuộc nhóm công việc:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              // Hiển thị thông tin nhóm công việc (cần kết nối với dữ liệu nhóm)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Nhóm công việc ${nhiemVu.groupId}'),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Xử lý xóa nhiệm vụ
        },
        child: Icon(Icons.delete),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}