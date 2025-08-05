import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NhiemVuModel>> _upcomingTasks;
  late Future<List<NhiemVuModel>> _expiredTasks;
  late Future<List<NhiemVuModel>> _uncompletedTasks;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    
    _upcomingTasks = _getTasksInTimeRange(dbProvider, now, oneHourLater);
    _expiredTasks = _getExpiredTasks(dbProvider);
    _uncompletedTasks = _getUncompletedTasks(dbProvider);
    
    // Giả sử có một hàm lấy người dùng hiện tại
    // _currentUser = await dbProvider.getCurrentUser();
  }

  Future<List<NhiemVuModel>> _getTasksInTimeRange(
      DatabaseProvider dbProvider, DateTime start, DateTime end) async {
    final allTasks = await dbProvider.getNhiemVuList();
    return allTasks.where((task) {
      final taskDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.startTime.hour,
        task.startTime.minute,
      );
      return taskDateTime.isAfter(start) && taskDateTime.isBefore(end);
    }).toList();
  }

  Future<List<NhiemVuModel>> _getExpiredTasks(DatabaseProvider dbProvider) async {
    final now = DateTime.now();
    final allTasks = await dbProvider.getNhiemVuList();
    return allTasks.where((task) {
      final taskEndDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.endTime.hour,
        task.endTime.minute,
      );
      return taskEndDateTime.isBefore(now) && !task.isCompleted;
    }).toList();
  }

  Future<List<NhiemVuModel>> _getUncompletedTasks(
      DatabaseProvider dbProvider) async {
    final today = DateTime.now();
    final tasks = await dbProvider.getNhiemVuByDate(today);
    return tasks.where((task) => !task.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: () {
                // Gửi email tổng hợp
                // NotificationService().sendDailySummaryEmail(
                //   context, 
                //   _currentUser!.email!
                // );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Sắp đến giờ (trước 1 tiếng)'),
              _buildTaskList(_upcomingTasks),
              _buildSectionHeader('Hết giờ thực hiện'),
              _buildTaskList(_expiredTasks),
              _buildSectionHeader('Chưa hoàn thành hôm nay'),
              _buildTaskList(_uncompletedTasks),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTaskList(Future<List<NhiemVuModel>> tasksFuture) {
    return FutureBuilder<List<NhiemVuModel>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }
        
        final tasks = snapshot.data ?? [];
        
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Không có nhiệm vụ nào'),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildTaskItem(tasks[index]);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(NhiemVuModel task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.subtitle),
            const SizedBox(height: 4),
            Text(
              '${task.startTime.format(context)} - ${task.endTime.format(context)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(DateFormat('dd/MM/yyyy').format(task.date)),
          ],
        ),
        trailing: Icon(
          task.isCompleted ? Icons.check_circle : Icons.pending,
          color: task.isCompleted ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}