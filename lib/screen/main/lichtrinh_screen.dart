import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/nhomviec.dart';
import 'package:cham_ly_thuyet/models/user.dart';
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

class LichtrinhWidget extends StatefulWidget {
  @override
  _LichtrinhWidgetState createState() => _LichtrinhWidgetState();
}

class _LichtrinhWidgetState extends State<LichtrinhWidget> {
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
    _loadData();
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

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<NhiemVuModel> _getTasksForSelectedDate(List<NhiemVuModel> allTasks) {
    return allTasks.where((task) => 
        task.date.year == _selectedDate.year &&
        task.date.month == _selectedDate.month &&
        task.date.day == _selectedDate.day).toList();
  }

  String get formattedDate {
  return DateFormat('dd/MM/yyyy', 'vi').format(_selectedDate); // Thêm locale 'vi'
}

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final allTasks = dbProvider.getNhiemVuList();
        final tasksForDate = _getTasksForSelectedDate(allTasks as List<NhiemVuModel>);

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Lịch trình'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          drawer: Thanhmenu(
            onMenuSelected: (index) {
              Navigator.pop(context);
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TrangchuWidget()),
                );
              }
            },
            selectedIndex: 2,
            currentUser: _currentUser,
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
                            CalendarWidget(
                            currentDate: _currentDate,
                            selectedDate: _selectedDate,
                            allTasks: allTasks as List<NhiemVuModel>,
                            onDateSelected: (newDate) {
                            setState(() {
                           _selectedDate = newDate;
                                });
                               },
                              ),
                            _buildTaskList(tasksForDate),
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

  Widget _buildCalendarGrid(List<NhiemVuModel> allTasks) {
    DateTime firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    int startingOffset = firstDay.weekday - 1;
    DateTime lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    int totalDays = lastDay.day;
    int prevMonthDays = DateTime(_currentDate.year, _currentDate.month, 0).day;
    int nextMonthDays = 42 - (startingOffset + totalDays);

    List<Widget> dayWidgets = [];
    List<String> weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    for (int i = 0; i < startingOffset; i++) {
      dayWidgets.add(
        Opacity(
          opacity: 0.5,
          child: Center(
            child: Text('${prevMonthDays - startingOffset + i + 1}'),
          ),
        ),
      );
    }

    for (int i = 1; i <= totalDays; i++) {
      bool isToday = i == DateTime.now().day && 
                    _currentDate.month == DateTime.now().month && 
                    _currentDate.year == DateTime.now().year;
      
      bool isSelected = i == _selectedDate.day && 
                       _currentDate.month == _selectedDate.month && 
                       _currentDate.year == _selectedDate.year;

      bool hasTasks = allTasks.any((task) => 
          task.date.day == i &&
          task.date.month == _currentDate.month &&
          task.date.year == _currentDate.year);

      dayWidgets.add(
        GestureDetector(
          onTap: () => setState(() {
            _selectedDate = DateTime(_currentDate.year, _currentDate.month, i);
          }),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : null,
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    '$i',
                    style: TextStyle(
                      color: isSelected ? Colors.white : 
                            (isToday ? Colors.blue : Colors.black),
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasTasks)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    for (int i = 1; i <= nextMonthDays; i++) {
      dayWidgets.add(
        Opacity(
          opacity: 0.5,
          child: Center(
            child: Text('$i'),
          ),
        ),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      padding: const EdgeInsets.all(8),
      children: dayWidgets,
    );
  }
}