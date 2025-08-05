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

  // My Life color scheme
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF7B68EE);
  static const Color accentColor = Color(0xFF50C878);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2C3E50);
  static const Color textSecondaryColor = Color(0xFF5A6C7D);

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
      final newUser = User(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        matkhau: _passwordController.text.trim(),
        avatar: (_urlController.text.trim().isEmpty) 
            ? 'assets/avatar.png' 
            : _urlController.text.trim(),
      );

      late int userId;
      
      final databaseProvider = context.read<DatabaseProvider>();
      if (databaseProvider != null) {
        final existingUser = await databaseProvider.getUserByEmail(newUser.email ?? '');
        if (existingUser != null) {
          _showError('Email đã được đăng ký. Vui lòng sử dụng email khác.');
          setState(() => _isLoading = false);
          return;
        }
        
        userId = await databaseProvider.insertUser(newUser);
      } else {
        final dbHelper = DatabaseHelper();
        
        final existingUser = await dbHelper.getUserByEmail(newUser.email ?? '');
        if (existingUser != null) {
          _showError('Email đã được đăng ký. Vui lòng sử dụng email khác.');
          setState(() => _isLoading = false);
          return;
        }
        
        userId = await dbHelper.insertUser(newUser);
      }
      
      if (userId > 0) {
        newUser.id = userId;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastRegisteredUser', json.encode(newUser.toJson()));
        await prefs.setBool('isFirstTime', false);
        
        _showSuccess('Đăng ký thành công! Chuyển đến trang đăng nhập...');
        
        _clearForm();
        
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            )),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            )),
          ],
        ),
        backgroundColor: accentColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Điều khoản sử dụng',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              '1. Bằng việc đăng ký tài khoản, bạn đồng ý tuân thủ các điều khoản sử dụng.\n\n'
              '2. Thông tin cá nhân của bạn sẽ được bảo mật theo chính sách bảo mật của chúng tôi.\n\n'
              '3. Bạn có trách nhiệm bảo mật thông tin đăng nhập của mình.\n\n'
              '4. Nghiêm cấm sử dụng ứng dụng cho các mục đích bất hợp pháp.\n\n'
              '5. Chúng tôi có quyền khóa tài khoản nếu phát hiện hành vi vi phạm.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondaryColor,
                height: 1.5,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Không đồng ý',
                style: GoogleFonts.inter(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                setState(() {
                  _acceptTerms = false;
                });
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Đồng ý',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                setState(() {
                  _acceptTerms = true;
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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo và tiêu đề
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.asset(
                            'assets/icon/logo.png',
                            width: 48,
                            height: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'My Life',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [primaryColor, secondaryColor],
                              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quản lý cuộc sống của bạn',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Tạo tài khoản mới',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Điền thông tin để bắt đầu hành trình của bạn',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form fields
                  _buildFormField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    icon: Icons.person_outline,
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
                    icon: Icons.email_outlined,
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
                    icon: Icons.lock_outline,
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
                    icon: Icons.image_outlined,
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
                  const SizedBox(height: 24),

                  // Checkbox điều khoản
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTermsDialog,
                            child: Text(
                              'Tôi đồng ý với điều khoản sử dụng',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  _isLoading 
                      ? _buildLoadingWidget()
                      : _buildActionButtons(),
                  
                  const SizedBox(height: 24),
                  
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        style: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              isPasswordVisible ?? false ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: textSecondaryColor,
              size: 20,
            ),
            onPressed: onTogglePassword,
          ) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tạo tài khoản...',
            style: GoogleFonts.inter(
              color: textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_outlined, size: 20),
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: Text(
                'Tạo tài khoản',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_outlined, size: 18),
                onPressed: _clearForm,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange[400]!, width: 1.5),
                  foregroundColor: Colors.orange[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  'Xóa form',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close_outlined, size: 18),
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
                  foregroundColor: const Color(0xFFE74C3C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  'Thoát',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Đã có tài khoản? ', 
            style: GoogleFonts.inter(
              fontSize: 16, 
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _goToLogin,
            child: Text(
              'Đăng nhập ngay', 
              style: GoogleFonts.inter(
                fontSize: 16, 
                color: primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}