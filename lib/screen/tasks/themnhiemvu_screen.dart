import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';

class ThemNhiemVu extends StatefulWidget {
  final List<NhomViec> availableGroups;
  final DateTime ngay;
  final Function(NhiemVuModel)? onTaskAdded;

  const ThemNhiemVu({
    Key? key,
    required this.availableGroups,
    required this.ngay,
    this.onTaskAdded,
  }) : super(key: key);

  @override
  _ThemNhiemVuState createState() => _ThemNhiemVuState();
}

class _ThemNhiemVuState extends State<ThemNhiemVu> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  NhomViec? _selectedGroup;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.ngay;
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: _startTime!.hour + 1, minute: _startTime!.minute);
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thời gian')),
        );
        return;
      }

      if (_endTime!.hour < _startTime!.hour || 
          (_endTime!.hour == _startTime!.hour && _endTime!.minute <= _startTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
        );
        return;
      }

      final newTask = NhiemVuModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        subtitle: _subtitleController.text,
        date: _selectedDate!,
        startTime: _startTime!,
        endTime: _endTime!,
        isCompleted: _isCompleted,
        groupId: _selectedGroup?.id,
      );

      try {
        final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
        await dbProvider.insertNhiemVu(newTask);
        
        if (widget.onTaskAdded != null) {
          widget.onTaskAdded!(newTask);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm nhiệm vụ thành công')),
        );
        
        Navigator.pop(context, newTask);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu nhiệm vụ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nhiệm vụ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề nhiệm vụ',
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
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
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
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _startTime = time;
                            if (_endTime != null && 
                                (time.hour > _endTime!.hour || 
                                (time.hour == _endTime!.hour && time.minute >= _endTime!.minute))) {
                              _endTime = TimeOfDay(hour: time.hour + 1, minute: time.minute);
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Bắt đầu',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_startTime?.format(context) ?? 'Chọn giờ'),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _endTime = time;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Kết thúc',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_endTime?.format(context) ?? 'Chọn giờ'),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NhomViec>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Nhóm việc',
                  border: OutlineInputBorder(),
                ),
                items: widget.availableGroups.map((group) {
                  return DropdownMenuItem<NhomViec>(
                    value: group,
                    child: Text(group.title),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Đã hoàn thành'),
                value: _isCompleted,
                onChanged: (value) {
                  setState(() {
                    _isCompleted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Lưu nhiệm vụ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}