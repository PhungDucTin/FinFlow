import 'package:flutter/material.dart';

//Đây là nơi chứa các màu sắc và hằng số dùng chung cho app

class AppColors {
  static const Color primary = Color(0xFF00796B); // Màu xanh lục đậm chủ đạo
  static const Color accent = Color(0xFF009688); // Màu xanh lục nhạt làm điểm nhấn
  static const Color income = Color(0xFF4CAF50); // Màu xanh lá cho Thu Nhập
  static const Color expense = Color(0xFFF44336); // Màu đỏ cho Chi Tiêu
  static const Color background = Color(0xFFF5F5F5); // Màu nền sáng
}

class AppStrings {
  static const String appName = "FinFlow"; // Tên ứng dụng
  static const String dbName = "finflow_data.db"; // Tên file Cơ sở Dữ Liệu
}