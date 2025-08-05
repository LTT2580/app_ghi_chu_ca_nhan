import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/main/thongbao_screen.dart';
import 'package:cham_ly_thuyet/widgets/app_bottom_navigation.dart';
import 'package:cham_ly_thuyet/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/thanhmenu_widget.dart';
import 'trangchu_screen.dart';
import 'nhomviec_screen.dart';
import 'tiendo_screen.dart';
import 'nhiemvu_screen.dart';
import '../tasks/themnhiemvu_screen.dart';
import '../../data/database_provider.dart';

class LichtrinhScreen extends StatefulWidget {
  @override
  _LichtrinhScreenState createState() => _LichtrinhScreenState();
}

class _LichtrinhScreenState extends State<LichtrinhScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 2;
  List<NhomViec> _availableGroups = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadGroups();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('currentUser');
      if (userJson != null && mounted) {
        setState(() {
          _currentUser = User.fromJson(json.decode(userJson));
        });
      }
    } catch (e) {
      print("Lỗi khi tải người dùng: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGroups() async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final groups = await dbProvider.getNhomViecList();
      if (mounted) {
        setState(() {
          _availableGroups = groups;
        });
      }
    } catch (e) {
      print("Lỗi khi tải nhóm việc: $e");
    }
  }

  List<NhiemVuModel> _getTasksForSelectedDate(List<NhiemVuModel> allTasks) {
    return allTasks.where((task) => 
        task.date.year == _selectedDate.year &&
        task.date.month == _selectedDate.month &&
        task.date.day == _selectedDate.day).toList();
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy', 'vi').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Lịch trình'),
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
  selectedIndex: 2, // Index cho lịch trình
  currentUser: _currentUser,
  onMenuSelected: (index) {
    // Xử lý khi chọn menu nếu cần
    print('Selected menu index: $index');
  },
),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildMonthControl(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            FutureBuilder<List<NhiemVuModel>>(
                              future: dbProvider.getNhiemVuList(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return CalendarWidget(
                                    currentDate: _currentDate,
                                    selectedDate: _selectedDate,
                                    allTasks: [],
                                    onDateSelected: (newDate) {
                                      setState(() {
                                        _selectedDate = newDate;
                                      });
                                    },
                                  );
                                } else {
                                  final allTasks = snapshot.data!;
                                  return CalendarWidget(
                                    currentDate: _currentDate,
                                    selectedDate: _selectedDate,
                                    allTasks: allTasks,
                                    onDateSelected: (newDate) {
                                      setState(() {
                                        _selectedDate = newDate;
                                      });
                                    },
                                  );
                                }
                              },
                            ),
                            FutureBuilder<List<NhiemVuModel>>(
                              future: dbProvider.getNhiemVuList(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return _buildTaskList([]);
                                } else {
                                  final allTasks = snapshot.data!;
                                  final tasksForDate = _getTasksForSelectedDate(allTasks);
                                  return _buildTaskList(tasksForDate);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildAddTaskButton(),
                  ],
                ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              _onBottomNavItemTapped(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskList(List<NhiemVuModel> tasksForDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Công việc ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (tasksForDate.isEmpty)
            const Text('Không có công việc nào trong ngày này',
                style: TextStyle(color: Colors.grey))
          else
            Column(
              children: tasksForDate.map((task) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: task.isCompleted ? Colors.green : Colors.blue,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.startTime.format(context)} - ${task.endTime.format(context)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (task.subtitle.isNotEmpty)
                        Text(
                          task.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          task.isCompleted ? Icons.undo : Icons.done,
                          color: task.isCompleted ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _toggleTaskStatus(task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTask(task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteTask(task),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(NhiemVuModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa nhiệm vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<DatabaseProvider>(context, listen: false).deleteNhiemVu(task.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _showAddTaskScreen,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('Thêm nhiệm vụ'),
          ],
        ),
      ),
    );
  }

  void _showAddTaskScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThemNhiemVu(
          availableGroups: _availableGroups,
          onTaskAdded: (newTask) {
            Provider.of<DatabaseProvider>(context, listen: false).insertNhiemVu(newTask);
          }, 
          ngay: DateTime.now(),
        ),
      ),
    );

    if (result != null && result is NhiemVuModel && mounted) {
      Provider.of<DatabaseProvider>(context, listen: false).insertNhiemVu(result);
    }
  }

  void _editTask(NhiemVuModel task) {
    TextEditingController taskController = TextEditingController(text: task.title);
    TextEditingController subtitleController = TextEditingController(text: task.subtitle);
    DateTime selectedDate = task.date;
    TimeOfDay startTime = task.startTime;
    TimeOfDay endTime = task.endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa công việc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công việc',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
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
                      setDialogState(() {
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
                ListTile(
                  title: const Text('Thời gian bắt đầu'),
                  trailing: Text(
                    startTime.format(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        startTime = time;
                        if (endTime.hour < time.hour || 
                            (endTime.hour == time.hour && endTime.minute <= time.minute)) {
                          endTime = TimeOfDay(hour: time.hour + 1, minute: time.minute);
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('Thời gian kết thúc'),
                  trailing: Text(
                    endTime.format(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        endTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final updatedTask = task.copyWith(
                  title: taskController.text,
                  subtitle: subtitleController.text,
                  date: selectedDate,
                  startTime: startTime,
                  endTime: endTime,
                );
                
                Provider.of<DatabaseProvider>(context, listen: false).updateNhiemVu(updatedTask);
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTaskStatus(NhiemVuModel task) {
    Provider.of<DatabaseProvider>(context, listen: false)
        .toggleNhiemVuStatus(task.id, !task.isCompleted);
  }

  Widget _buildMonthControl() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentDate),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 30),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
      try {
        _selectedDate = DateTime(_currentDate.year, _currentDate.month, _selectedDate.day);
      } catch (e) {
        _selectedDate = DateTime(_currentDate.year, _currentDate.month + 1, 0);
      }
    });
  }

  void _onBottomNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          MaterialPageRoute(builder: (context) => NhomViecWidget()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TienDoWidget()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NhiemVu()),
        );
        break;
    }
  }
}