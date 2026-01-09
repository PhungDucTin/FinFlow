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

// ===== RESPONSIVE HELPER FUNCTIONS =====
class ResponsiveSize {
  // Tính font size responsive dựa vào screen width
  static double getFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return baseFontSize * 0.8; // Điện thoại rất nhỏ
    } else if (width < 480) {
      return baseFontSize * 0.9; // Điện thoại nhỏ
    } else if (width < 768) {
      return baseFontSize; // Điện thoại bình thường
    } else if (width < 1024) {
      return baseFontSize * 1.2; // Tablet nhỏ
    } else {
      return baseFontSize * 1.4; // Tablet lớn / Desktop
    }
  }

  // Tính padding responsive dựa vào screen width
  static double getPadding(BuildContext context, double basePadding) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return basePadding * 0.75;
    } else if (width < 480) {
      return basePadding * 0.85;
    } else if (width < 768) {
      return basePadding;
    } else if (width < 1024) {
      return basePadding * 1.25;
    } else {
      return basePadding * 1.5;
    }
  }

  // Tính icon size responsive
  static double getIconSize(BuildContext context, double baseIconSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return baseIconSize * 0.8;
    } else if (width < 480) {
      return baseIconSize * 0.9;
    } else if (width < 768) {
      return baseIconSize;
    } else if (width < 1024) {
      return baseIconSize * 1.2;
    } else {
      return baseIconSize * 1.4;
    }
  }

  // Kiểm tra thiết bị là mobile, tablet hay desktop
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1024) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  // Tính aspect ratio cho grid responsive
  static double getGridAspectRatio(BuildContext context, int columns) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return 0.7;
    } else if (width < 480) {
      return 0.75;
    } else if (width < 768) {
      return 0.85;
    } else {
      return 1.0;
    }
  }
}

enum DeviceType { mobile, tablet, desktop }

// ===== HELPER FUNCTIONS (CŨ) =====
IconData getIconByKey(String key) {
  switch (key) {
    // --- Chi tiêu ---
    case 'food': return Icons.fastfood;
    case 'transport': return Icons.directions_car;
    case 'house': return Icons.home;
    case 'bill': return Icons.receipt_long;
    case 'health': return Icons.medical_services;
    case 'coffee': return Icons.local_cafe;
    case 'shopping': return Icons.shopping_bag;
    case 'game': return Icons.sports_esports;
    case 'travel': return Icons.flight_takeoff;
    case 'education': return Icons.school;
    case 'friends': return Icons.people;
    case 'book': return Icons.menu_book;
    case 'party': return Icons.celebration;
    // --- Tài chính ---
    case 'savings': return Icons.savings;
    case 'invest': return Icons.trending_up;
    case 'pay_debt': return Icons.money_off;
    case 'loan': return Icons.attach_money;
    case 'family': return Icons.family_restroom;
    case 'charity': return Icons.volunteer_activism;
    // --- Thu nhập ---
    case 'salary': return Icons.account_balance_wallet;
    case 'part_time': return Icons.access_time;
    case 'debt_collection': return Icons.input;
    case 'other_income': return Icons.monetization_on;
    // Mặc định
    default: return Icons.category;
  }
}

Color getColorFromHex(String hexColor) {
  try {
    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
    buffer.write(hexColor.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.grey; 
  }
}

Color getDarkerColor(Color color) {
  final hsvColor = HSVColor.fromColor(color);
  
  return hsvColor
      .withSaturation((hsvColor.saturation * 1.8).clamp(0.0, 1.0)) 
      .withValue((hsvColor.value * 0.8).clamp(0.0, 1.0))
      .toColor();
}

// Format tiền tệ Việt Nam (thêm dấu chấm phân cách hàng nghìn)
String formatCurrencyVN(String amount) {
  final numAmount = int.tryParse(amount) ?? 0;
  final str = numAmount.toString();
  final buffer = StringBuffer();
  
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  
  return buffer.toString();
}