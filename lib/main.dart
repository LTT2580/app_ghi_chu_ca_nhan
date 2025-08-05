import 'dart:convert';
import 'dart:io';
import 'package:cham_ly_thuyet/models/user.dart';
import 'package:cham_ly_thuyet/screen/main/welcom_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cham_ly_thuyet/data/app_database.dart';
import 'package:cham_ly_thuyet/data/database_provider.dart';
import 'package:cham_ly_thuyet/screen/auth/dangky.dart';
import 'package:cham_ly_thuyet/screen/auth/dangnhap.dart';
import 'package:cham_ly_thuyet/screen/main/trangchu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. KHỞI TẠO LOCALE CHO WINDOWS - CÁCH MỚI
  try {
    // CÁCH 1: Khởi tạo không chỉ định đường dẫn
    await initializeDateFormatting('vi_VN', null);
    print('Đã khởi tạo định dạng ngày tháng cho locale vi_VN');
    
    // CÁCH 2: Hoặc khởi tạo với locale mặc định
    // Intl.defaultLocale = 'vi_VN';
    // await initializeDateFormatting();
  } catch (e) {
    print('Lỗi khởi tạo locale: $e');
  }

  // 2. KHỞI TẠO DATABASE
  try {
    await AppDatabase.initialize();
    print('Database initialized successfully');
  } catch (e) {
    print('Database initialization failed: $e');
  }

 runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Life App',
      debugShowCheckedModeBanner: false,
      
      // CẤU HÌNH NGÔN NGỮ VIỆT NAM
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('vi', 'VN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Thêm delegates mặc định để tránh lỗi
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      
      // MÀN HÌNH KHỞI ĐỘNG
      home:  WelcomeScreen(),
      
      // ĐỊNH NGHĨA CÁC MÀN HÌNH
      routes: {
        '/welcome': (context) =>  WelcomeScreen(),
        '/login': (context) => const Dangnhap(),
        '/register': (context) => const Dangky(),
        '/home': (context) =>  TrangchuWidget(),
      },
    );
  }
}