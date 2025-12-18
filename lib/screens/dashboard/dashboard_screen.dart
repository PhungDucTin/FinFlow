import 'package:finflow/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../add_transaction/add_transaction_screen.dart';
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
    Future.microtask(() => context.read<TransactionProvider>().loadData());
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
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
                const Text(
                  "Tổng số dư",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  formatter.format(provider.balance), // Lấy số dư từ Provider
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      "Thu nhập",
                      provider.totalIncome,
                      Colors.greenAccent,
                    ),
                    _buildSummaryItem(
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
                                content: const Text("Bạn có chắc chắn muốn xóa giao dịch này không?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false), // Hủy -> Trả về false
                                    child: const Text("Hủy"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true), // Đồng ý -> Trả về true
                                    child: const Text("Xóa", style: TextStyle(color: Colors.red)),
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
                          // 1. Lưu dữ liệu cũ
                          final deletedItem = transaction;
                          
                          // 2. LƯU PROVIDER VÀO BIẾN (Để dùng sau này mà không cần context)
                          final transactionProvider = context.read<TransactionProvider>();
                          
                          // 3. Xóa trong Database
                          transactionProvider.deleteTransaction(
                            transaction.id!, 
                            transaction.date
                          );

                          // 4. Hiện thông báo
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Đã xóa giao dịch'),
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'HOÀN TÁC',
                                textColor: Colors.yellow,
                                onPressed: () async {
                                  print("--- Bắt đầu hoàn tác ---");

                                  // Chờ xíu cho DB ổn định
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  
                                  // ❌ XÓA DÒNG NÀY ĐI: if (!context.mounted) return;
                                  // Vì dòng đã xóa rồi thì context chắc chắn không còn mounted,
                                  // chúng ta không cần check nữa vì đã có biến transactionProvider ở trên.

                                  // Tạo đối tượng mới (Bỏ ID)
                                  final restoreTransaction = TransactionModel(
                                    amount: deletedItem.amount,
                                    note: deletedItem.note,
                                    date: deletedItem.date,
                                    categoryId: deletedItem.categoryId,
                                    type: deletedItem.type,
                                    categoryName: deletedItem.categoryName,
                                    categoryIcon: deletedItem.categoryIcon,
                                    categoryColor: deletedItem.categoryColor,
                                  );
                                  
                                  try {
                                    // SỬA Ở ĐÂY: Dùng biến 'transactionProvider' thay vì 'context.read...'
                                    await transactionProvider.addTransaction(restoreTransaction);
                                    print("--- Hoàn tác THÀNH CÔNG ---");
                                  } catch (e) {
                                    print("--- LỖI HOÀN TÁC: $e ---");
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        
                        // Nội dung hiển thị (Card cũ của bạn)
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isExpense
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              child: Icon(
                                isExpense
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isExpense
                                    ? AppColors.expense
                                    : AppColors.income,
                              ),
                            ),
                            title: Text(transaction.categoryName ?? 'Danh mục'),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(transaction.date),
                            ),
                            trailing: Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                                  .format(transaction.amount),
                              style: TextStyle(
                                color: isExpense
                                    ? AppColors.expense
                                    : AppColors.income,
                                fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Chuyển sang màn hình Thêm giao dịch
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    final formatter = NumberFormat.compact(
      locale: 'vi_VN',
    ); // Format số gọn (1tr, 200k)
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
