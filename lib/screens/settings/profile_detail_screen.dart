import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../configs/constants.dart';
import '../../services/auth_service.dart';
import '../../view_models/transaction_provider.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final AuthService _authService = AuthService();

  // Hàm hiển thị hộp thoại đổi tên
  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đổi tên hiển thị"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nhập tên mới"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _authService.updateDisplayName(controller.text.trim());
                if (mounted) {
                  setState(() {}); // Làm mới để hiện tên mới
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final transactionProvider = context.watch<TransactionProvider>();
    
    // 1. Xử lý Ngày tham gia
    String joinedDate = user?.metadata.creationTime != null 
        ? DateFormat('dd/MM/yyyy').format(user!.metadata.creationTime!) 
        : 'Đang cập nhật';

    // 2. Xử lý Trạng thái xác thực
    bool isVerified = user?.emailVerified ?? false;
    // Nếu login bằng Google thì mặc định là đã xác minh
    if (user?.providerData.any((p) => p.providerId == 'google.com') ?? false) {
      isVerified = true;
    }

    // 3. Thống kê nhanh
    int totalTransactions = transactionProvider.transactions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: const Text('Thông tin cá nhân', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Phần Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null 
                    ? Text(user?.email?[0].toUpperCase() ?? 'U', 
                      style: const TextStyle(fontSize: 40, color: Colors.white))
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            // Badge Hạng thành viên (Gợi ý tương lai)
            Chip(
              label: Text(totalTransactions > 10 ? 'Thành viên Bạc' : 'Thành viên Mới'),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // Nhóm 1: Thông tin tài khoản
            _buildSectionTitle('Tài khoản'),
            _buildInfoTile(
              label: 'Tên hiển thị', 
              value: user?.displayName ?? 'Chưa đặt tên',
              icon: Icons.edit,
              onTap: () => _showEditNameDialog(user?.displayName ?? ''),
            ),
            _buildInfoTile(
              label: 'Trạng thái', 
              value: isVerified ? 'Đã xác minh' : 'Chưa xác minh',
              icon: isVerified ? Icons.verified : Icons.warning,
              iconColor: isVerified ? Colors.blue : Colors.orange,
            ),
            _buildInfoTile(
              label: 'Phương thức', 
              value: user?.providerData.any((p) => p.providerId == 'google.com') ?? false ? 'Google' : 'Email/Mật khẩu',
              icon: Icons.login,
            ),

            const SizedBox(height: 20),
            // Nhóm 2: Thống kê & Hoạt động
            _buildSectionTitle('Hoạt động'),
            _buildInfoTile(
              label: 'Ngày tham gia', 
              value: joinedDate,
              icon: Icons.calendar_today,
            ),
            _buildInfoTile(
              label: 'Tổng giao dịch', 
              value: '$totalTransactions giao dịch',
              icon: Icons.receipt_long,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildInfoTile({required String label, required String value, required IconData icon, Color? iconColor, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20) : null,
      ),
    );
  }
}