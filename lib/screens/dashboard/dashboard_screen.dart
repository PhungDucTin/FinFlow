import 'package:finflow/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../transaction_detail/transaction_detail_screen.dart';
import '../../../view_models/transaction_provider.dart';
import '../../../configs/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi Provider để tải dữ liệu ngay khi mở màn hình
    // listen: false vì trong initState không được vẽ lại UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu từ Provider
    final provider = context.watch<TransactionProvider>();
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text("FinFlow", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THẺ TỔNG QUAN (Balance Card)
          Container(
            margin: EdgeInsets.all(ResponsiveSize.getPadding(context, 16)),
            padding: EdgeInsets.all(ResponsiveSize.getPadding(context, 20)),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Tổng số dư",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: ResponsiveSize.getFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getPadding(context, 10)),
                Text(
                  formatter.format(provider.balance), // Lấy số dư từ Provider
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveSize.getFontSize(context, 30),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getPadding(context, 20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      context,
                      "Thu nhập",
                      provider.totalIncome,
                      Colors.greenAccent,
                    ),
                    _buildSummaryItem(
                      context,
                      "Chi tiêu",
                      provider.totalExpense,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. DANH SÁCH GIAO DỊCH
          Expanded(
            child: provider.transactions.isEmpty
                ? const Center(child: Text("Chưa có giao dịch trong tháng này"))
                : ListView.builder(
                    itemCount: provider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = provider.transactions[index];
                      final isExpense = transaction.type == 'expense';

                      // --- SỬA TỪ ĐÂY: Bọc Card trong Dismissible ---
                      return Dismissible(
                        // Key là bắt buộc để Flutter biết dòng nào bị xóa
                        key: Key(transaction.id.toString()),

                        // Chỉ cho phép vuốt từ phải sang trái
                        direction: DismissDirection.endToStart,

                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Xác nhận xóa"),
                                content: const Text(
                                  "Bạn có chắc chắn muốn xóa giao dịch này không?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pop(false), // Hủy -> Trả về false
                                    child: const Text("Hủy"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pop(true), // Đồng ý -> Trả về true
                                    child: const Text(
                                      "Xóa",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        // Màu nền đỏ và icon thùng rác khi vuốt
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        // Xử lý khi vuốt xong
                        onDismissed: (direction) {
                          // 1. Lưu dữ liệu để hoàn tác
                          final deletedItem = transaction;
                          final transactionProvider = context
                              .read<TransactionProvider>();
                          final String? currentUserId = deletedItem.userId;

                          // 2. Xóa khỏi Database
                          transactionProvider.deleteTransaction(
                            transaction.id!,
                            transaction.date,
                          );

                          // 3. XỬ LÝ SNACKBAR ĐÚNG CHUẨN:

                          // Bước A: Ẩn ngay lập tức SnackBar đang hiện (nếu có)
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          // Bước B: Hiển thị SnackBar mới
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Đã xoá giao dịch"),
                              // Thời gian hiển thị ngắn gọn: 2 giây
                              duration: const Duration(seconds: 2),
                              // Floating giúp nó nổi lên đẹp hơn, tránh che khuất nội dung quan trọng
                              behavior: SnackBarBehavior.floating,
                              // Margin giúp nó cách đáy màn hình 1 chút (tránh bị đè bởi thanh điều hướng ảo)
                              margin: const EdgeInsets.only(
                                bottom: 80,
                                left: 10,
                                right: 10,
                              ),

                              action: SnackBarAction(
                                label: 'HOÀN TÁC',
                                textColor: Colors
                                    .amberAccent, // Màu vàng sáng cho dễ nhìn
                                onPressed: () async {
                                  // Logic hoàn tác (Giữ nguyên logic của bạn)
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  final restoreTransaction = TransactionModel(
                                    userId: currentUserId,
                                    amount: deletedItem.amount,
                                    note: deletedItem.note,
                                    date: deletedItem.date,
                                    categoryId: deletedItem.categoryId,
                                    type: deletedItem.type,
                                    // Các trường phụ khác...
                                  );
                                  await transactionProvider.addTransaction(
                                    restoreTransaction,
                                  );
                                },
                              ),
                            ),
                          );
                        },

                        // Nội dung hiển thị (Card cập nhật)
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailScreen(
                                  transaction: transaction,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Padding(
                            padding: EdgeInsets.all(ResponsiveSize.getPadding(context, 12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hàng 1: Icon + Tên danh mục + Giờ
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Icon + Tên danh mục
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isExpense
                                                ? Colors.red[50]
                                                : Colors.green[50],
                                            radius: ResponsiveSize.getIconSize(context, 24),
                                            child: Icon(
                                              isExpense
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: isExpense
                                                  ? AppColors.expense
                                                  : AppColors.income,
                                              size: ResponsiveSize.getIconSize(context, 20),
                                            ),
                                          ),
                                          SizedBox(width: ResponsiveSize.getPadding(context, 12)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transaction.categoryName ?? 'Danh mục',
                                                  style: TextStyle(
                                                    fontSize: ResponsiveSize.getFontSize(context, 14),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (transaction.note.isNotEmpty)
                                                  Text(
                                                    transaction.note,
                                                    style: TextStyle(
                                                      fontSize: ResponsiveSize.getFontSize(context, 12),
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Giờ + Số tiền (Cột phải)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(transaction.date),
                                          style: TextStyle(
                                            fontSize: ResponsiveSize.getFontSize(context, 12),
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'vi_VN',
                                            symbol: 'đ',
                                          ).format(transaction.amount),
                                          style: TextStyle(
                                            color: isExpense
                                                ? AppColors.expense
                                                : AppColors.income,
                                            fontWeight: FontWeight.bold,
                                            fontSize: ResponsiveSize.getFontSize(context, 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Hàng 2: Ngày tháng năm (nếu cần)
                                SizedBox(height: ResponsiveSize.getPadding(context, 8)),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(transaction.date),
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.getFontSize(context, 11),
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ),
                      );
                      // --- KẾT THÚC PHẦN SỬA ---
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, double amount, Color color) {
    final formatter = NumberFormat.compact(
      locale: 'vi_VN',
    ); // Format số gọn (1tr, 200k)
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveSize.getFontSize(context, 14),
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveSize.getFontSize(context, 16),
          ),
        ),
      ],
    );
  }
}
