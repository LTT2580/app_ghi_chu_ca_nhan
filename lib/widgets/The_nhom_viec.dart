// File: lib/widgets/work_group_card.dart

import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/tasks/chitietnhomviec_screen.dart';
import 'package:flutter/material.dart';


class WorkGroupCard extends StatefulWidget {
  final NhomViec nhomViec;
  final bool isCompactView; // true cho trang chủ, false cho nhomviec_screen
  final bool showDeleteOption; // có hiển thị tùy chọn xóa không
  final Function(String)? onDelete;
  final Function(NhiemVuModel, bool)? onTaskToggle;

  const WorkGroupCard({
    Key? key,
    required this.nhomViec,
    this.isCompactView = false,
    this.showDeleteOption = false,
    this.onDelete,
    this.onTaskToggle,
  }) : super(key: key);

  @override
  _WorkGroupCardState createState() => _WorkGroupCardState();
}

class _WorkGroupCardState extends State<WorkGroupCard> {
  Widget _buildCompactCard() {
    final completedTasks = widget.nhomViec.tasks.where((task) => task.isCompleted).length;
    final totalTasks = widget.nhomViec.tasks.length;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChitietnhomviecWidget(group: widget.nhomViec),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.nhomViec.colorValue.withOpacity(0.1),
          border: Border.all(color: widget.nhomViec.colorValue, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.nhomViec.colorValue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.nhomViec.timeRange,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.nhomViec.colorValue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.nhomViec.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              widget.nhomViec.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedTasks/$totalTasks nhiệm vụ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.nhomViec.colorValue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard() {
    Widget cardContent = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChitietnhomviecWidget(group: widget.nhomViec),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.nhomViec.colorValue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.nhomViec.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${(widget.nhomViec.completionPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: widget.nhomViec.completionPercentage == 1 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.nhomViec.description, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Khung giờ: ${widget.nhomViec.timeRange}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Hoàn thành: ${widget.nhomViec.completionStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Divider(),
              Text('Các nhiệm vụ:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.nhomViec.tasks.map((task) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.nhomViec.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(task.title),
                subtitle: Text(task.subtitle),
                trailing: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    if (value != null && widget.onTaskToggle != null) {
                      setState(() => task.isCompleted = value);
                      widget.onTaskToggle!(task, value);
                    }
                  },
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );

    // Wrap với Dismissible nếu có chức năng xóa
    if (widget.showDeleteOption && widget.onDelete != null) {
      return Dismissible(
        key: Key(widget.nhomViec.id),
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
              content: const Text('Bạn có chắc muốn xóa nhóm việc này?'),
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
        onDismissed: (direction) => widget.onDelete!(widget.nhomViec.id),
        child: cardContent,
      );
    }

    return cardContent;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCompactView ? _buildCompactCard() : _buildFullCard();
  }
}