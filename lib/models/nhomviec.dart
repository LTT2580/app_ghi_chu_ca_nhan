import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'nhiemvu.dart';

class NhomViec {
  final String id;
  final String title;
  final String description;
  final String timeRange;
  late final List<NhiemVuModel> tasks;
  final String? userId;
  final String? color;
  final String? parentGroupId;

  NhomViec({
    required this.id,
    required this.title,
    required this.description,
    required this.timeRange,
    this.tasks = const [],
    this.userId,
    this.color,
    this.parentGroupId,
  });

  double get completionPercentage {
    if (tasks.isEmpty) return 0;
    return tasks.where((task) => task.isCompleted).length / tasks.length;
  }

  String get completionStatus {
    if (tasks.isEmpty) return 'Chưa có nhiệm vụ';
    return '${tasks.where((task) => task.isCompleted).length}/${tasks.length} nhiệm vụ';
  }

  Color get colorValue {
    if (color == null) return Colors.blue;
    return Color(int.parse('FF$color', radix: 16));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeRange': timeRange,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'userId': userId,
      'color': color,
      'parentGroupId': parentGroupId,
    };
  }

  factory NhomViec.fromJson(Map<String, dynamic> json) {
    return NhomViec(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timeRange: json['timeRange'],
      tasks: (json['tasks'] as List)
          .map((taskJson) => NhiemVuModel.fromJson(taskJson))
          .toList(),
      userId: json['userId'],
      color: json['color'],
      parentGroupId: json['parentGroupId'],
    );
  }

  NhomViec copyWith({
    String? id,
    String? title,
    String? description,
    String? timeRange,
    List<NhiemVuModel>? tasks,
    String? userId,
    String? color,
    String? parentGroupId,
  }) {
    return NhomViec(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeRange: timeRange ?? this.timeRange,
      tasks: tasks ?? this.tasks,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      parentGroupId: parentGroupId ?? this.parentGroupId,
    );
  }
}

class NhomViecGroup {
  final DateTime date;
  final List<NhomViec> groups;

  NhomViecGroup({
    required this.date,
    required this.groups,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }

  factory NhomViecGroup.fromJson(Map<String, dynamic> json) {
    return NhomViecGroup(
      date: DateTime.parse(json['date']),
      groups: (json['groups'] as List)
          .map((groupJson) => NhomViec.fromJson(groupJson))
          .toList(),
    );
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
}