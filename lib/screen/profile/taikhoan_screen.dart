import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/database_helper.dart';
import 'package:provider/provider.dart';

class TaiKhoanScreen extends StatefulWidget {
  const TaiKhoanScreen({Key? key}) : super(key: key);

  @override
  _TaiKhoanScreenState createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  User? _currentUser;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('currentUser');
      final int? userId = prefs.getInt('currentUserId');
      
      if (userJson != null) {
        setState(() {
          _currentUser = User.fromJson(json.decode(userJson));
          _initializeControllers();
        });
      } else if (userId != null) {
        final user = await _dbHelper.getUserById(userId);
        if (user != null) {
          setState(() {
            _currentUser = user;
            _initializeControllers();
          });
          await prefs.setString('currentUser', json.encode(user.toJson()));
        }
      }
    } catch (e) {
      print("Error loading current user: $e");
      _showError('Đã có lỗi khi tải thông tin người dùng');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeControllers() {
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name ?? '';
      _emailController.text = _currentUser!.email ?? '';
      _avatarController.text = _currentUser!.avatar ?? 'assets/avatar.png';
    }
  }

  Future<void> _updateUserInfo() async {
    if (_currentUser == null) return;
    
    // Kiểm tra dữ liệu
    if (_nameController.text.isEmpty) {
      _showError('Vui lòng nhập họ tên');
      return;
    }
    
    if (_emailController.text.isEmpty) {
      _showError('Vui lòng nhập email');
      return;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError('Email không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Sử dụng copyWith để cập nhật thông tin
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        avatar: _avatarController.text.trim().isEmpty 
            ? 'assets/avatar.png' 
            : _avatarController.text.trim(),
      );

      // Kiểm tra nếu email thay đổi và đã tồn tại
      if (updatedUser.email != _currentUser!.email) {
        final existingUser = await _dbHelper.getUserByEmail(updatedUser.email!);
        if (existingUser != null && existingUser.id != updatedUser.id) {
          _showError('Email đã được sử dụng bởi tài khoản khác');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Cập nhật trong database
      final result = await _dbHelper.updateUser(updatedUser);
      
      if (result > 0) {
        // Cập nhật thành công
        setState(() => _currentUser = updatedUser);
        
        // Cập nhật SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', json.encode(updatedUser.toJson()));
        
        // Cập nhật Provider nếu có
        if (context.mounted) {
          final provider = Provider.of<DatabaseProvider>(context, listen: false);
          provider.updateUser(updatedUser);
        }
        
        _showSuccess('Cập nhật thông tin thành công');
      } else {
        _showError('Cập nhật không thành công');
      }
    } catch (e) {
      print("Error updating user: $e");
      _showError('Đã có lỗi khi cập nhật thông tin: ${e.toString()}');
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Không tìm thấy thông tin người dùng'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadCurrentUser,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar - Sửa lỗi null check ở đây
                              Center(
                                child: _buildAvatar(),
                              ),
                              const SizedBox(height: 20),
                              
                              // Name
                              const Text(
                                'Họ và tên:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _currentUser?.name ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Email
                              const Text(
                                'Email:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _currentUser?.email ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Update button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  onPressed: _showUpdateDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  label: const Text(
                                    'Cập nhật thông tin',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Hàm xây dựng avatar an toàn
  Widget _buildAvatar() {
    final avatar = _currentUser?.avatar;
    
    if (avatar == null || avatar.isEmpty) {
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 50),
      );
    }
    
    try {
      if (avatar.startsWith('http')) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(avatar),
        );
      } else {
        return CircleAvatar(
          radius: 60,
          backgroundImage: AssetImage(avatar),
        );
      }
    } catch (e) {
      print("Error loading avatar: $e");
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.error),
      );
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Avatar field
                TextFormField(
                  controller: _avatarController,
                  decoration: const InputDecoration(
                    labelText: 'URL ảnh đại diện',
                    prefixIcon: Icon(Icons.image),
                    hintText: 'assets/avatar.png hoặc URL',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserInfo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );
  }
}