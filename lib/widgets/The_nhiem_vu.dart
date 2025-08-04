// Dùng chung cho cả trang chủ và nhiemvu
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:flutter/material.dart';

Widget _buildTaskItem(
  NhiemVuModel task, 
  BuildContext context, {
  required VoidCallback onDelete,
  required Function(bool) onStatusChange,
  required List<NhomViec> workGroups,
}) {
  final group = workGroups.firstWhere(
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
    onDismissed: (direction) => onDelete(),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted ? Colors.green[200]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox tùy chỉnh
          GestureDetector(
            onTap: () => onStatusChange(!task.isCompleted),
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
                      task.formattedDate,
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
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              } else if (value == 'edit') {
                // Xử lý chỉnh sửa
              }
            },
          ),
        ],
      ),
    ),
  );
}