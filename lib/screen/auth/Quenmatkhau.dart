import 'package:cham_ly_thuyet/data/database_helper.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:flutter/material.dart';
import 'Dangnhap.dart';

class QuenmatkhauScreen extends StatefulWidget {
  const QuenmatkhauScreen({Key? key}) : super(key: key);

  @override
  _QuenmatkhauScreenState createState() => _QuenmatkhauScreenState();
}

class _QuenmatkhauScreenState extends State<QuenmatkhauScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Đặt lại mật khẩu'),
                  ),
          ],
        ),
      ),
    );
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Vui lòng nhập email');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showError('Vui lòng nhập mật khẩu mới');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sử dụng DatabaseHelper
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserByEmail(email);
      
      if (user != null) {
        // Sử dụng copyWith để cập nhật mật khẩu
        final updatedUser = user.copyWith(matkhau: _newPasswordController.text);
        
        // Cập nhật vào database
        await dbHelper.updateUser(updatedUser);
        
        _showSuccess('Cập nhật mật khẩu thành công. Vui lòng đăng nhập lại.');
        
        // Quay lại màn hình đăng nhập sau 2 giây
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dangnhap()),
        );
      } else {
        _showError('Không tìm thấy người dùng với email này');
      }
    } catch (e) {
      _showError('Cập nhật mật khẩu thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}