import 'package:finflow/configs/constants.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isEnglish = false;
  bool _reminderEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // 1. Mục Ngôn ngữ
          ListTile(
            title: const Text(
              'Ngôn ngữ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_isEnglish ? 'English' : 'Tiếng Việt'),
            trailing: Switch(
              value: _isEnglish,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _isEnglish = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã đổi ngôn ngữ sang ${_isEnglish ? 'English' : 'Tiếng Việt'} (áp dụng cho các màn hình hỗ trợ đa ngôn ngữ).',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          
          // 2. Mục nhắc nhở chi tiêu
          SwitchListTile(
            title: const Text(
              'Nhắc nhở ghi chép chi tiêu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Gửi thông báo nhắc bạn cập nhật giao dịch hàng ngày.',
            ),
            value: _reminderEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _reminderEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _reminderEnabled
                        ? 'Đã bật nhắc nhở. Bạn có thể cấu hình chi tiết sau.'
                        : 'Đã tắt nhắc nhở.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),

          const SizedBox(height: 30),

          // 3. Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              // 1. Hiện hộp thoại xác nhận
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Đăng xuất"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                // 2. Gọi hàm đăng xuất từ AuthService
                await AuthService().signOut();

                // 3. Chuyển về màn hình Login (Xoá hết lịch sử back)
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            }
          ),
        ],
      ),
    );
  }
}


