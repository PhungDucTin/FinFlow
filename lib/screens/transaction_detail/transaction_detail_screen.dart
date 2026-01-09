import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../configs/constants.dart';
import '../../services/database_helper.dart';
import '../../view_models/transaction_provider.dart';
import '../add_transaction/add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late CategoryModel? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  void _loadCategory() async {
    final cat = await DatabaseHelper.instance.getCategoryById(widget.transaction.categoryId);
    setState(() {
      _category = cat;
      _isLoading = false;
    });
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xoá giao dịch"),
        content: const Text("Bạn có chắc muốn xoá giao dịch này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>().deleteTransaction(widget.transaction.id!, widget.transaction.date);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Chi tiết giao dịch", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isExpense = widget.transaction.type == 'expense';
    final catColor = _category != null ? getColorFromHex(_category!.colorHex) : AppColors.primary;
    final amountDisplay = widget.transaction.amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isExpense ? "Chi tiết chi tiêu" : "Chi tiết thu nhập",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với danh mục
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: catColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _category != null ? getIconByKey(_category!.iconKey) : Icons.category,
                      color: catColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _category?.name ?? "Chưa xác định",
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _category?.description ?? "",
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(context, 13),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Số tiền
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Số tiền",
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(context, 16),
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${isExpense ? '- ' : '+ '}$amountDisplay đ",
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: isExpense ? AppColors.expense : AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    // Tài khoản
                    _buildDetailRow("Tài khoản", "Tiền mặt"),
                    const Divider(height: 24),

                    // Trạng thái
                    _buildDetailRow("Trạng thái", "Hoàn thành"),
                    const Divider(height: 24),

                    // Phân loại
                    _buildDetailRow(
                      "Phân loại",
                      isExpense ? "Chi tiêu" : "Thu nhập",
                      valueColor: isExpense ? AppColors.expense : AppColors.income,
                    ),
                    const Divider(height: 24),

                    // Ghi chú
                    if (widget.transaction.note.isNotEmpty) ...[
                      _buildDetailRow("Ghi chú", widget.transaction.note),
                      const Divider(height: 24),
                    ],

                    // Thời gian
                    _buildDetailRow(
                      "Thời gian",
                      "${DateFormat('HH:mm').format(widget.transaction.date)} - ${DateFormat('dd/MM/yyyy').format(widget.transaction.date)}",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
  // Điều hướng sang màn hình AddTransactionScreen và truyền dữ liệu cũ
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTransactionScreen(
        transactionToEdit: widget.transaction, // <--- TRUYỀN DỮ LIỆU
      ),
    ),
  );
  
  // Khi quay lại từ màn hình sửa, đóng màn hình chi tiết để về danh sách (hoặc reload)
  if (context.mounted) {
    Navigator.pop(context); 
  }
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Chỉnh sửa giao dịch",
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleteTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Xoá giao dịch",
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(context, 16),
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.teal.shade900,
          ),
        ),
      ],
    );
  }
}
