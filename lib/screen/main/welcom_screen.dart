// File: lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:cham_ly_thuyet/screen/auth/dangnhap.dart'; // Import trang đăng nhập thực của bạn
import 'package:intl/date_symbol_data_local.dart'; // Thêm import này

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi');
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Bắt đầu animation
    _animationController.forward();

    // Auto navigate sau 5 giây đến trang đăng nhập
    Future.delayed(Duration(seconds: 5), () {
      _navigateToLogin();
    });
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Dangnhap(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  // Thêm method để user có thể skip waiting time
  void _skipToLogin() {
    _navigateToLogin();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.8, 1.0, curve: Curves.easeInOut),
                      )),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: _skipToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade600,
                          ),
                          child: Text(
                            'Bỏ qua',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Spacer(flex: 2),
              
              // Logo với animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icon/logo.png', // Đường dẫn đến logo của bạn
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback khi không tìm thấy logo
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  size: 80,
                                  color: Colors.blue.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 40),

              // Text "My Life" với animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        'My Life',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 16),

              // Subtitle với animation delay
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
                    )),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                      )),
                      child: Text(
                        'Làm chủ cuộc sống của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),

              Spacer(flex: 2),

              // Progress indicator với countdown
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(0.6, 1.0, curve: Curves.easeInOut),
                    )),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade400,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang khởi tạo ứng dụng...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}