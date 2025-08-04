import 'package:cham_ly_thuyet/data/database_helper.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'Dangnhap.dart';

class Dangky extends StatefulWidget {
  const Dangky({super.key});

  @override  
  State<Dangky> createState() => _DangkyState();
}

class _DangkyState extends State<Dangky> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _urlController = TextEditingController(text: 'assets/avatar.png');
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      _showError('Vui lòng đồng ý với điều khoản sử dụng');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo đối tượng User mới (LOẠI BỎ xacnhanmatkhau)
      final newUser = User(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        matkhau: _passwordController.text.trim(),
        avatar: (_urlController.text.trim().isEmpty) 
            ? 'assets/avatar.png' 
            : _urlController.text.trim(),
      );

      // Sử dụng Provider hoặc DatabaseHelper trực tiếp
      late int userId;
      
      final databaseProvider = context.read<DatabaseProvider>();
      if (databaseProvider != null) {
        // Kiểm tra email đã tồn tại
        final existingUser = await databaseProvider.getUserByEmail(newUser.email ?? '');
        if (existingUser != null) {
          _showError('Email đã được đăng ký. Vui lòng sử dụng email khác.');
          setState(() => _isLoading = false);
          return;
        }
        
        userId = await databaseProvider.insertUser(newUser);
      } else {
        // Sử dụng DatabaseHelper trực tiếp
        final dbHelper = DatabaseHelper();
        
        // Kiểm tra email đã tồn tại
        final existingUser = await dbHelper.getUserByEmail(newUser.email ?? '');
        if (existingUser != null) {
          _showError('Email đã được đăng ký. Vui lòng sử dụng email khác.');
          setState(() => _isLoading = false);
          return;
        }
        
        userId = await dbHelper.insertUser(newUser);
      }
      
      if (userId > 0) {
        // Cập nhật ID cho user
        newUser.id = userId;
        
        // Lưu thông tin user vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastRegisteredUser', json.encode(newUser.toJson()));
        await prefs.setBool('isFirstTime', false);
        
        _showSuccess('Đăng ký thành công! Chuyển đến trang đăng nhập...');
        
        // Clear form
        _clearForm();
        
        // Chuyển đến màn hình đăng nhập sau 2 giây
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dangnhap()),
        );
      } else {
        _showError('Đăng ký không thành công. Vui lòng thử lại.');
      }
    } catch (e) {
      _showError('Đã có lỗi khi đăng ký: ${e.toString()}');
      print("Error in _register: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _urlController.text = 'assets/avatar.png';
    setState(() {
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
      _acceptTerms = false;
    });
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final databaseProvider = context.read<DatabaseProvider>();
      if (databaseProvider != null) {
        final user = await databaseProvider.getUserByEmail(email);
        return user != null;
      } else {
        final dbHelper = DatabaseHelper();
        final user = await dbHelper.getUserByEmail(email);
        return user != null;
      }
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Dangnhap()),
    );
  }

  Future<void> _showTermsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Điều khoản sử dụng'),
          content: const SingleChildScrollView(
            child: Text(
              '1. Bằng việc đăng ký tài khoản, bạn đồng ý tuân thủ các điều khoản sử dụng.\n\n'
              '2. Thông tin cá nhân của bạn sẽ được bảo mật theo chính sách bảo mật của chúng tôi.\n\n'
              '3. Bạn có trách nhiệm bảo mật thông tin đăng nhập của mình.\n\n'
              '4. Nghiêm cấm sử dụng ứng dụng cho các mục đích bất hợp pháp.\n\n'
              '5. Chúng tôi có quyền khóa tài khoản nếu phát hiện hành vi vi phạm.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đồng ý'),
              onPressed: () {
                setState(() {
                  _acceptTerms = true;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Không đồng ý'),
              onPressed: () {
                setState(() {
                  _acceptTerms = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo và tiêu đề
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                           'assets/images/logo.png',
                            width: 50,
                            height: 50,
                           ),               
                        const SizedBox(height: 50),
                        Text(
                          'My Plant',
                          style: TextStyle(
                            fontSize: 48,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Điền thông tin để bắt đầu sử dụng ứng dụng',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form fields
                  _buildFormField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      if (value.trim().length < 2) {
                        return 'Họ tên phải có ít nhất 2 ký tự';
                      }
                      if (!RegExp(r'^[a-zA-ZàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ\s]+$')
                          .hasMatch(value.trim())) {
                        return 'Họ tên chỉ được chứa chữ cái';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFormField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Định dạng email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFormField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    icon: Icons.lock,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 8) {
                        return 'Mật khẩu phải có ít nhất 8 ký tự';
                      }
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])').hasMatch(value)) {
                        return 'Mật khẩu phải có chữ hoa, chữ thường và số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildFormField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onTogglePassword: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildFormField(
                    controller: _urlController,
                    label: 'URL hình ảnh (tùy chọn)',
                    icon: Icons.image,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value != 'assets/avatar.png') {
                        final urlRegex = RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$');
                        if (!urlRegex.hasMatch(value) && !value.startsWith('assets/')) {
                          return 'URL không hợp lệ';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Checkbox điều khoản
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: Colors.green[600],
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTermsDialog,
                            child: Text(
                              'Tôi đồng ý với điều khoản sử dụng',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Buttons
                  _isLoading 
                      ? _buildLoadingWidget()
                      : _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                  
                  // Link đăng nhập
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.green[600]),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              isPasswordVisible ?? false ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: onTogglePassword,
          ) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.green[600]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tạo tài khoản...',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add, size: 24),
            onPressed: _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
            label: const Text(
              'Đăng ký',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.clear_all, size: 20),
                onPressed: _clearForm,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange[400]!, width: 2),
                  foregroundColor: Colors.orange[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Xóa form',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Thoát',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Đã có tài khoản? ', 
            style: TextStyle(
              fontSize: 16, 
              color: Colors.grey[600]
            )
          ),
          GestureDetector(
            onTap: _goToLogin,
            child: Text(
              'Đăng nhập ngay', 
              style: TextStyle(
                fontSize: 16, 
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )
            ),
          ),
        ],
      ),
    );
  }
}