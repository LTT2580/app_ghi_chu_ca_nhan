import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:cham_ly_thuyet/screen/main/thongbao_screen.dart';
import 'package:cham_ly_thuyet/widgets/app_bottom_navigation.dart';
import 'package:cham_ly_thuyet/widgets/thanhmenu_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../profile/taikhoan_screen.dart';
import 'trangchu_screen.dart';
import 'lichtrinh_screen.dart';
import 'nhomviec_screen.dart';
import 'nhiemvu_screen.dart';
import '../../data/database_provider.dart';

class TienDoWidget extends StatefulWidget {
  const TienDoWidget({super.key});

  @override
  State<TienDoWidget> createState() => _TienDoWidgetState();
}

class _TienDoWidgetState extends State<TienDoWidget> {
  int _selectedIndex = 3;
  int _menuSelectedIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  List<TaskCompletionData> _completionData = [];
  List<Map<String, dynamic>> _groupStats = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('currentUser');
      
      if (userJson != null) {
        setState(() {
          _currentUser = User.fromJson(json.decode(userJson));
        });
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải thông tin người dùng');
      print("Error loading user: $e");
    }
  }

  Future<void> _loadData() async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final stats = await dbProvider.getCompletionStats();
      final groupStats = await dbProvider.getGroupStats();

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      List<TaskCompletionData> tempData = [];
      for (int i = 5; i >= 0; i--) {
        final month = currentMonth - i <= 0 ? 12 + (currentMonth - i) : currentMonth - i;
        final year = currentMonth - i <= 0 ? currentYear - 1 : currentYear;
        
        tempData.add(TaskCompletionData(
          month: _getMonthName(month),
          completedTasks: (stats['completedTasks'] ?? 0) + i * 2,
          totalTasks: (stats['totalTasks'] ?? 0) + i * 2 + 3,
          monthNumber: month,
          year: year,
        ));
      }

      setState(() {
        _completionData = tempData;
        _groupStats = groupStats;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('Lỗi khi tải dữ liệu tiến độ');
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Tháng 1';
      case 2: return 'Tháng 2';
      case 3: return 'Tháng 3';
      case 4: return 'Tháng 4';
      case 5: return 'Tháng 5';
      case 6: return 'Tháng 6';
      case 7: return 'Tháng 7';
      case 8: return 'Tháng 8';
      case 9: return 'Tháng 9';
      case 10: return 'Tháng 10';
      case 11: return 'Tháng 11';
      case 12: return 'Tháng 12';
      default: return '';
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onMenuSelected(int index) {
    setState(() => _menuSelectedIndex = index);
    Navigator.pop(context);
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrangchuWidget()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TaiKhoanScreen()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dangky()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến độ hoàn thành nhiệm vụ'),
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
          selectedIndex: 4, // Index cho trang chủ
          currentUser: _currentUser,
          onMenuSelected: (index) {
    // Xử lý khi chọn menu nếu cần
          print('Selected menu index: $index');
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu đồ hoàn thành nhiệm vụ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCompletionChart(),
                  const SizedBox(height: 24),
                  _buildCompletionDetails(),
                  const SizedBox(height: 24),
                  _buildGroupProgress(),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _handleBottomNavSelection,
      ),
    );
  }
  

  // Hàm xử lý khi chọn item bottom nav
  void _handleBottomNavSelection(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrangchuWidget()));
        break;
      case 1: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhomViecWidget()));
        break;
      case 2: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LichtrinhScreen()));
        break;
      case 3: 
        // Đang ở màn hình này, không cần làm gì
        break;
      case 4: 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhiemVu()));
        break;
    }
  }

  Widget _buildCompletionChart() {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _completionData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${_completionData[index].month}\n${_completionData[index].year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%');
                },
                reservedSize: 40,
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: _completionData.map((data) {
            final percentage = (data.completedTasks / data.totalTasks * 100);
            return BarChartGroupData(
              x: _completionData.indexOf(data),
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  color: _getColorForPercentage(percentage),
                  width: 20,
                  borderRadius: BorderRadius.zero,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompletionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết hoàn thành nhiệm vụ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            const TableRow(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Tháng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Hoàn thành',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Tổng số',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Tỷ lệ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ..._completionData.map((data) => TableRow(
                  decoration: BoxDecoration(
                    color: _completionData.indexOf(data) % 2 == 0
                        ? Colors.grey.shade100
                        : Colors.white,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${data.month} ${data.year}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        data.completedTasks.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        data.totalTasks.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${(data.completedTasks / data.totalTasks * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getColorForPercentage(data.completedTasks / data.totalTasks * 100),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiến độ theo nhóm việc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_groupStats.isEmpty)
          const Center(child: Text('Không có dữ liệu nhóm việc'))
        else
          Column(
            children: _groupStats.map((group) {
              final completedCount = group['completed_tasks'] ?? 0;
              final totalCount = group['total_tasks'] ?? 1;
              final percentage = totalCount > 0 ? (completedCount / totalCount * 100) : 0.0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group['title'] ?? 'Không có tiêu đề',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getColorForPercentage(percentage.toDouble()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        color: _getColorForPercentage(percentage.toDouble()),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedCount/$totalCount nhiệm vụ hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Nhóm việc'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Lịch trình'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tiến độ'),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Nhiệm vụ'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber[800],
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TrangchuWidget()));
            break;
          case 1: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhomViecWidget()));
            break;
          case 2: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LichtrinhScreen()));
            break;
          case 3: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TienDoWidget()));
            break;
          case 4: 
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NhiemVu()));
            break;
        }
      },
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

class TaskCompletionData {
  final String month;
  final int completedTasks;
  final int totalTasks;
  final int monthNumber;
  final int year;

  TaskCompletionData({
    required this.month,
    required this.completedTasks,
    required this.totalTasks,
    required this.monthNumber,
    required this.year,
  });
}