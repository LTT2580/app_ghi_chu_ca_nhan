import 'package:flutter/material.dart';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';

class TaskListItem extends StatelessWidget {
  final NhiemVuModel task;
  final List<NhomViec> workGroups;
  final Function(NhiemVuModel) onToggleStatus;
  final Function(NhiemVuModel) onEdit;
  final Function(NhiemVuModel) onDelete;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.workGroups,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      onDismissed: (direction) => onDelete(task),
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
            if (value != null) onToggleStatus(task);
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
            onSelected: (value) {
              if (value == 'delete') onDelete(task);
              else if (value == 'edit') onEdit(task);
            },
          ),
        ),
      ),
    );
  }
}