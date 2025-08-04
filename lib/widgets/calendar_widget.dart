import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cham_ly_thuyet/models/nhiemvu.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime currentDate;
  final DateTime selectedDate;
  final List<NhiemVuModel> allTasks;
  final Function(DateTime) onDateSelected; // Thêm callback function

  const CalendarWidget({
    Key? key,
    required this.currentDate,
    required this.selectedDate,
    required this.allTasks,
    required this.onDateSelected, // Thêm callback
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    DateTime firstDay = DateTime(currentDate.year, currentDate.month, 1);
    int startingOffset = firstDay.weekday - 1;
    DateTime lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);
    int totalDays = lastDay.day;
    int prevMonthDays = DateTime(currentDate.year, currentDate.month, 0).day;
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
                    currentDate.month == DateTime.now().month && 
                    currentDate.year == DateTime.now().year;
      
      bool isSelected = i == selectedDate.day && 
                       currentDate.month == selectedDate.month && 
                       currentDate.year == selectedDate.year;

      bool hasTasks = allTasks.any((task) => 
          task.date.day == i &&
          task.date.month == currentDate.month &&
          task.date.year == currentDate.year);

      dayWidgets.add(
        GestureDetector(
          onTap: ()  {
             onDateSelected(DateTime(currentDate.year, currentDate.month, i));
          },
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