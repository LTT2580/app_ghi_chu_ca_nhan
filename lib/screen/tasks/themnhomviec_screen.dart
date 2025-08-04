import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_provider.dart';

class ThemNhomViecScreen extends StatefulWidget {
  final Function(NhomViec)? onSave;
  final String? userId;

  const ThemNhomViecScreen({super.key, this.onSave, this.userId});

  @override
  State<ThemNhomViecScreen> createState() => _ThemNhomViecScreenState();
}

class _ThemNhomViecScreenState extends State<ThemNhomViecScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeRangeController = TextEditingController();
  final List<NhiemVuModel> _tasks = [];
  Color _selectedColor = Colors.blue;
  final List<Color> _colorOptions = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeRangeController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      if (!_validateTimeRange(_timeRangeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khung giờ không hợp lệ. Vui lòng nhập theo định dạng HH:mm-HH:mm'),
          ),
        );
        return;
      }

      final newGroup = NhomViec(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        timeRange: _timeRangeController.text,
        tasks: _tasks,
        userId: widget.userId,
        color: _selectedColor.value.toRadixString(16).substring(2),
      );

      try {
        final dbProvider = DatabaseProvider();
        await dbProvider.insertNhomViec(newGroup);

        for (var task in _tasks) {
          await dbProvider.insertNhiemVu(task.copyWith(groupId: newGroup.id));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu nhóm việc thành công')),
        );

        if (widget.onSave != null) {
          widget.onSave!(newGroup);
        }

        if (mounted) Navigator.pop(context, newGroup);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu nhóm việc: $e')),
        );
      }
    }
  }

  bool _validateTimeRange(String timeRange) {
    try {
      final parts = timeRange.split('-');
      if (parts.length != 2) return false;
      
      final startTime = parts[0].trim();
      final endTime = parts[1].trim();
      
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      if (startParts.length != 2 || endParts.length != 2) return false;
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      if (startHour < 0 || startHour > 23 || endHour < 0 || endHour > 23) return false;
      if (startMinute < 0 || startMinute > 59 || endMinute < 0 || endMinute > 59) return false;
      
      if (startHour > endHour || (startHour == endHour && startMinute >= endMinute)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addNewTask() async {
    final taskTitleController = TextEditingController();
    final taskSubtitleController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? startTime = TimeOfDay.now();
    TimeOfDay? endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    bool isCompleted = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Thêm nhiệm vụ mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: taskTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề*',
                      border: OutlineInputBorder(),
                      hintText: 'Nhập tiêu đề nhiệm vụ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: taskSubtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                      hintText: 'Nhập mô tả nhiệm vụ',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('vi', 'VN'),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày*',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate!)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          startTime = time;
                          if (endTime != null && 
                              (time.hour > endTime!.hour || 
                              (time.hour == endTime!.hour && time.minute >= endTime!.minute))) {
                            endTime = TimeOfDay(hour: time.hour + 1, minute: time.minute);
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Thời gian bắt đầu*',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(startTime?.format(context) ?? 'Chọn giờ'),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          endTime = time;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Thời gian kết thúc*',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(endTime?.format(context) ?? 'Chọn giờ'),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Hoàn thành'),
                    value: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        isCompleted = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (taskTitleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập tiêu đề nhiệm vụ'),
                      ),
                    );
                    return;
                  }

                  if (startTime == null || endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng chọn thời gian'),
                      ),
                    );
                    return;
                  }

                  if (endTime!.hour < startTime!.hour || 
                      (endTime!.hour == startTime!.hour && endTime!.minute <= startTime!.minute)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
                      ),
                    );
                    return;
                  }

                  final newTask = NhiemVuModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: taskTitleController.text,
                    subtitle: taskSubtitleController.text,
                    date: selectedDate!,
                    startTime: startTime!,
                    endTime: endTime!,
                    isCompleted: isCompleted,
                    userId: widget.userId,
                  );
                  setState(() {
                    _tasks.add(newTask);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Thêm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editTask(int index) async {
    final task = _tasks[index];
    final taskTitleController = TextEditingController(text: task.title);
    final taskSubtitleController = TextEditingController(text: task.subtitle);
    DateTime selectedDate = task.date;
    TimeOfDay startTime = task.startTime;
    TimeOfDay endTime = task.endTime;
    bool isCompleted = task.isCompleted;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Chỉnh sửa nhiệm vụ', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: taskTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề*',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: taskSubtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() {
                          startTime = time;
                          if (endTime.hour < time.hour || 
                              (endTime.hour == time.hour && endTime.minute <= time.minute)) {
                            endTime = TimeOfDay(hour: time.hour + 1, minute: time.minute);
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Thời gian bắt đầu',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(startTime.format(context)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() {
                          endTime = time;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Thời gian kết thúc',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(endTime.format(context)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Hoàn thành'),
                    value: isCompleted,
                    onChanged: (value) {
                      setState(() {
                        isCompleted = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (taskTitleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập tiêu đề nhiệm vụ'),
                      ),
                    );
                    return;
                  }

                  if (endTime.hour < startTime.hour || 
                      (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
                      ),
                    );
                    return;
                  }

                  final updatedTask = NhiemVuModel(
                    id: task.id,
                    title: taskTitleController.text,
                    subtitle: taskSubtitleController.text,
                    date: selectedDate,
                    startTime: startTime,
                    endTime: endTime,
                    isCompleted: isCompleted,
                    userId: task.userId,
                    groupId: task.groupId,
                  );
                  setState(() {
                    _tasks[index] = updatedTask;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nhóm việc', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _saveGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Màu sắc nhóm*',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = _colorOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: _selectedColor == color
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                          child: _selectedColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Tên nhóm việc*',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên nhóm việc',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên nhóm việc';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Mô tả',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mô tả nhóm việc',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Khung giờ* (HH:mm-HH:mm)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _timeRangeController,
                  decoration: InputDecoration(
                    hintText: 'VD: 08:00-17:00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập khung giờ';
                    }
                    if (!_validateTimeRange(value)) {
                      return 'Khung giờ không hợp lệ. Vui lòng nhập theo định dạng HH:mm-HH:mm';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Các nhiệm vụ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _addNewTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text('Thêm nhiệm vụ', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _tasks.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Chưa có nhiệm vụ nào',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: _selectedColor.withOpacity(0.1),
                            child: ListTile(
                              onTap: () => _editTask(index),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.subtitle.isNotEmpty) 
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(task.subtitle),
                                    ),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(task.date)} • ${task.startTime.format(context)} - ${task.endTime.format(context)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: task.isCompleted ? Colors.green[100] : Colors.red[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          task.isCompleted ? 'Đã hoàn thành' : 'Chưa hoàn thành',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: task.isCompleted ? Colors.green[800] : Colors.red[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xác nhận'),
                                      content: const Text('Bạn có chắc muốn xóa nhiệm vụ này?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _tasks.removeAt(index);
                                            });
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}