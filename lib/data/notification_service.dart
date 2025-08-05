import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cham_ly_thuyet/models/nhiemvu.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService._internal() {
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {},
    );
  }

  Future<void> scheduleTaskNotifications(BuildContext context) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final tasks = await dbProvider.getNhiemVuList();

    for (var task in tasks) {
      // Thông báo trước 1 tiếng
      final reminderTime = _calculateReminderTime(task);
      await _scheduleNotification(
        id: task.id.hashCode,
        title: 'Sắp đến giờ: ${task.title}',
        body: 'Nhiệm vụ bắt đầu lúc ${task.startTime.format(context)}',
        scheduledTime: reminderTime,
      );

      // Thông báo khi hết giờ
      final endTime = _calculateEndTime(task);
      await _scheduleNotification(
        id: task.id.hashCode + 1,
        title: 'Hết giờ: ${task.title}',
        body: 'Thời gian thực hiện đã kết thúc',
        scheduledTime: endTime,
      );
    }
  }

  tz.TZDateTime _calculateReminderTime(NhiemVuModel task) {
    final now = tz.TZDateTime.now(tz.local);
    final taskDateTime = tz.TZDateTime(
      tz.local,
      task.date.year,
      task.date.month,
      task.date.day,
      task.startTime.hour,
      task.startTime.minute,
    );

    return taskDateTime.subtract(const Duration(hours: 1));
  }

  tz.TZDateTime _calculateEndTime(NhiemVuModel task) {
    return tz.TZDateTime(
      tz.local,
      task.date.year,
      task.date.month,
      task.date.day,
      task.endTime.hour,
      task.endTime.minute,
    );
  }

  Future<void> _scheduleNotification({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime scheduledTime,
}) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_notifications',
        'Task Notifications',
        channelDescription: 'Thông báo về nhiệm vụ',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: // XÓA DÒNG NÀY
        UILocalNotificationDateInterpretation.absoluteTime, // XÓA DÒNG NÀY
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

  Future<void> sendDailySummaryEmail(
      BuildContext context, String userEmail) async {
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final today = DateTime.now();
    final tasks = await dbProvider.getNhiemVuByDate(today);
    final uncompletedTasks = tasks.where((task) => !task.isCompleted).toList();

    if (uncompletedTasks.isEmpty) return;

    final emailBody = _createEmailBody(uncompletedTasks);

    final Email email = Email(
      body: emailBody,
      subject: 'Tổng hợp nhiệm vụ chưa hoàn thành ngày ${DateFormat('dd/MM/yyyy').format(today)}',
      recipients: [userEmail],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      debugPrint('Lỗi khi gửi email: $error');
    }
  }

// Thêm hàm định dạng thời gian
String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// Sửa hàm _createEmailBody
String _createEmailBody(List<NhiemVuModel> tasks) {
  String body = 'Bạn có ${tasks.length} nhiệm vụ chưa hoàn thành hôm nay:\n\n';
  
  for (var task in tasks) {
    body += '- ${task.title}: '
            '${_formatTime(task.startTime)} - '
            '${_formatTime(task.endTime)}\n'; // ✅ Sử dụng hàm mới
  }
  
  body += '\nVui lòng hoàn thành các nhiệm vụ này càng sớm càng tốt!';
  return body;
}

}