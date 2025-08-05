import 'package:cham_ly_thuyet/screen/auth/Dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:cham_ly_thuyet/screen/main/lichtrinh_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhiemvu_screen.dart';
import 'package:cham_ly_thuyet/screen/main/nhomviec_screen.dart';
import 'package:cham_ly_thuyet/screen/main/tiendo_screen.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';
import 'package:cham_ly_thuyet/screen/profile/taikhoan_screen.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class UnifiedDrawer extends StatelessWidget {
  final Function(int)? onMenuSelected;
  final int selectedIndex;
  final User? currentUser;

  const UnifiedDrawer({
    Key? key,
    this.onMenuSelected,
    required this.selectedIndex,
    this.currentUser,
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
              backgroundImage: AssetImage(
                currentUser?.avatar ?? 'assets/images/avatar.jpg',
              ),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          
          // Trang chủ
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            title: 'Trang chủ',
            index: 0,
            onTap: () => _navigateToScreen(context, TrangchuWidget()),
          ),
          
          // Nhiệm vụ
          _buildDrawerItem(
            context: context,
            icon: Icons.list,
            title: 'Nhiệm vụ',
            index: 1,
            onTap: () => _navigateToScreen(context, NhiemVu()),
          ),
          
          // Lịch trình
          _buildDrawerItem(
            context: context,
            icon: Icons.event,
            title: 'Lịch trình',
            index: 2,
            onTap: () => _navigateToScreen(context, LichtrinhScreen()),
          ),
          
          // Nhóm việc
          _buildDrawerItem(
            context: context,
            icon: Icons.bar_chart,
            title: 'Nhóm việc',
            index: 3,
            onTap: () => _navigateToScreen(context, NhomViecWidget()),
          ),
          
          // Tiến độ
          _buildDrawerItem(
            context: context,
            icon: Icons.warning,
            title: 'Tiến độ',
            index: 4,
            onTap: () => _navigateToScreen(context, TienDoWidget()),
          ),
          
         const Divider(color: Colors.black),

          // Thông tin tài khoản
          _buildDrawerItem(
            context: context,
            icon: Icons.info,
            title: 'Thông tin',
            index: 5,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaiKhoanScreen()),
              );
            },
          ),
          
          // Đăng ký (nếu cần)
          _buildDrawerItem(
            context: context,
            icon: Icons.app_registration,
            title: 'Đăng ký',
            index: 6,
            onTap: () => _navigateToScreen(context, Dangky()),
          ),
          
          const Divider(color: Colors.black),
          
          // Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Dangnhap()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.pop(context);
        if (onMenuSelected != null) {
          onMenuSelected!(index);
        }
        onTap();
      },
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}