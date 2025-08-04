import 'package:flutter/material.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:cham_ly_thuyet/screen/main/lichtrinh_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhomviec_screen.dart';
import 'package:cham_ly_thuyet/screen/main/tiendo_screen.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';
import 'package:cham_ly_thuyet/screen/profile/taikhoan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  final User? currentUser;
  final int selectedIndex;
  final Function(int) onMenuSelected;

  const AppDrawer({
    Key? key,
    required this.currentUser,
    required this.selectedIndex,
    required this.onMenuSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser?.name ?? 'Khách'),
            accountEmail: Text(currentUser?.email ?? 'Chưa đăng nhập'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                currentUser?.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Trang chủ',
            index: 0,
            route: TrangchuWidget(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list,
            title: 'Nhóm việc',
            index: 1,
            route: const NhomViecWidget(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event,
            title: 'Lịch trình',
            index: 2,
            route: LichtrinhWidget(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Tiến độ',
            index: 3,
            route: const TienDoWidget(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.warning,
            title: 'Nhiệm vụ',
            index: 4,
            route: const NhiemVu(),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Thông tin cá nhân',
            index: 5,
            route: const TaiKhoanScreen(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Cài đặt',
            index: 6,
            route: Container(), // Thay bằng màn hình cài đặt thực tế
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    required Widget route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (route is Widget) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => route),
          );
        }
        onMenuSelected(index);
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Dangnhap()),
        (route) => false,
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}