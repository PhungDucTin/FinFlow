import 'package:finflow/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Cần import gói này
import 'package:intl/date_symbol_data_local.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'configs/constants.dart';
import 'view_models/transaction_provider.dart';
import 'view_models/category_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite ffi for desktop platforms (Windows/Linux/macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Lỗi Firebase (Có thể bỏ qua nếu chạy Offline): $e");
  }

  // Khởi tạo định dạng ngày tháng Tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  runApp(
    // KẾT NỐI PROVIDER TẠI ĐÂY
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadAll()),
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
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const DashboardScreen(), // Màn hình chính
    );
  }
}