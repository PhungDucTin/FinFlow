import 'package:finflow/screens/dashboard/dashboard_screen.dart';
import 'package:finflow/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Cần import gói này
import 'package:intl/date_symbol_data_local.dart';

import 'configs/constants.dart';
import 'view_models/transaction_provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBT3EeHOfBN6nhoDSKqbmXS1AbPUjncY1c",
        appId: "1:910639759238:android:369586eed79bea992fb607",
        messagingSenderId: "910639759238",
        projectId: "finflow-b37a5",
        storageBucket: "finflow-b37a5.firebasestorage.app",
      ),
    );
  } catch (e) {
    print("⚠️ Lỗi Firebase: $e");
  }

  // Khởi tạo định dạng ngày tháng Tiếng Việt
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    print("⚠️ Lỗi intl: $e");
  }

  runApp(
    // KẾT NỐI PROVIDER TẠI ĐÂY
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TransactionProvider())],
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
      home: const LoginScreen(), // Màn hình đăng nhập
      routes: {'/dashboard': (context) => const DashboardScreen()},
    );
  }
}
