import 'package:finflow/configs/constants.dart';
import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }
}


