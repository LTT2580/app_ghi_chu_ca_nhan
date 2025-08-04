import 'package:cham_ly_thuyet/data/database_helper.dart';
import 'package:cham_ly_thuyet/screen/auth/Quenmatkhau.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Dangky.dart';

class Dangnhap extends StatefulWidget {
  const Dangnhap({super.key});

  @override
  State<Dangnhap> createState() => _DangnhapState();
}

class _DangnhapState extends State<Dangnhap> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreeToPolicy = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('savedEmail');
      final rememberMe = prefs.getBool('rememberMe') ?? false;
      
      if (rememberMe && savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = rememberMe;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('savedEmail', _emailController.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('savedEmail');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  Future<void> _handleLogin() async {
    // Kiểm tra điều khoản
    if (!_agreeToPolicy) {
      _showError('Bạn cần đồng ý với điều khoản của ứng dụng để tiếp tục!');
      return;
    }

    // Validate form
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      // Kiểm tra kết nối database
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserByEmail(email);
      
      if (user == null) {
        _showError('Tài khoản không tồn tại. Vui lòng kiểm tra lại email.');
        return;
      }

      if (user.matkhau != password) {
        _showError('Mật khẩu không chính xác. Vui lòng thử lại.');
        return;
      }

      if (user.id == null) {
        _showError('Tài khoản không có ID. Vui lòng đăng ký lại.');
        return;
      }

      // Lưu thông tin người dùng hiện tại
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', json.encode(user.toJson()));
      await prefs.setInt('currentUserId', user.id!);
      await prefs.setBool('isLoggedIn', true);
      
      // Lưu thông tin đăng nhập nếu người dùng chọn "Ghi nhớ"
      await _saveCredentials();

      // Hiển thị thông báo thành công
      _showSuccess('Xin chào ${user.name ?? "Người dùng"}! Đăng nhập thành công.');
      
      // Chờ một chút để người dùng thấy thông báo
      await Future.delayed(const Duration(seconds: 1));
      
      // Chuyển đến trang chính
      if (!mounted) return;
      _goToTrangChu();
      
    } catch (e) {
      _showError('Đã có lỗi xảy ra khi đăng nhập: ${e.toString()}');
      print('Login error: $e');
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
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Dangky()),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuenmatkhauScreen()),
    );
  }

  void _goToTrangChu() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TrangchuWidget()),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _isPasswordVisible = false;
      _agreeToPolicy = false;
      _rememberMe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo/Title
                Text(
                  'My plant',
                  style: TextStyle(
                    fontSize: 100,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đăng nhập vào tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Form container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email field
                        const Text(
                          'Email người dùng:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            hintText: 'Nhập email của bạn',
                            prefixIcon: const Icon(Icons.email, color: Colors.grey),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        const Text(
                          'Mật khẩu:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            hintText: 'Nhập mật khẩu của bạn',
                            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: _isLoading ? null : () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _isLoading ? null : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Ghi nhớ thông tin đăng nhập'),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Forgot password and Login button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _isLoading ? null : _goToForgotPassword,
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            _isLoading
                                ? const SizedBox(
                                    width: 100,
                                    height: 40,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.login, size: 20),
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20, 
                                        vertical: 12
                                      ),
                                    ),
                                    label: const Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),                          
                                  ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Policy agreement checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToPolicy,
                              onChanged: _isLoading ? null : (value) {
                                setState(() {
                                  _agreeToPolicy = value ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Tôi đồng ý với chính sách và điều khoản của ứng dụng',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Clear form button
                if (!_isLoading)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear_all, size: 20),
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text('Xóa thông tin', style: TextStyle(fontSize: 14)),
                  ),
                const SizedBox(height: 16),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _goToRegister,
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}