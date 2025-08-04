import 'package:cham_ly_thuyet/screen/auth/Dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/Dangnhap.dart';
import 'package:cham_ly_thuyet/screen/profile/taikhoan_screen.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
class Thanhmenu extends StatelessWidget {
  final Function(int) onMenuSelected;
  final int selectedIndex;
  final User? currentUser;

  const Thanhmenu({
    Key? key,
    required this.onMenuSelected,
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
              backgroundImage: AssetImage(currentUser?.avatar ?? 'assets/images/avatar.jpg'),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang chủ'),
            selected: selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              onMenuSelected(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Thông tin'),
            selected: selectedIndex == 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaiKhoanScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.app_registration),
            title: const Text('Đăng ký'),
            selected: selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Dangky()),
              );
            },
          ),
          const Divider(color: Colors.black),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Dangnhap()),
              );
            },
          ),
        ],
      ),
    );
  }
}