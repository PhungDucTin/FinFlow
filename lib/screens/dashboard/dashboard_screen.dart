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
  // Local UI state for tabs and bottom nav
  int _selectedFilterIndex = 0; // 0 = expense, 1 = income
  int _selectedBottomIndex = 0;
  bool _isGridView = false;
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
    final filteredTransactions = provider.transactions.where((t) {
      if (_selectedFilterIndex == 0) return t.type == 'expense';
      return t.type == 'income';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
        children: [
            // Top gradient header + tabs
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text('Theo ngày', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Hôm nay', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        // Calendar Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Tab selectors + view toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedFilterIndex = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _selectedFilterIndex == 0 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.arrow_upward, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Text('Khoản chi tiêu', style: TextStyle(color: _selectedFilterIndex == 0 ? AppColors.primary : Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedFilterIndex = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _selectedFilterIndex == 1 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.arrow_downward, color: Colors.blueAccent),
                                        const SizedBox(width: 8),
                                        Text('Khoản thu về', style: TextStyle(color: _selectedFilterIndex == 1 ? AppColors.primary : Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _isGridView = !_isGridView),
                          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
                          tooltip: _isGridView ? 'Chế độ danh sách' : 'Chế độ lưới',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 2. DANH SÁCH GIAO DỊCH / or Empty State
          Expanded(
            child: filteredTransactions.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder illustration
                      Container(
                        height: 280,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inbox_rounded, size: 140, color: Color(0xFFB8E6DD)),
                              SizedBox(height: 16),
                              Text('Không có dữ liệu', style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Hãy thêm chi tiêu & thu nhập ...', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120, left: 12, right: 12, top: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          final isExpense = transaction.type == 'expense';
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
                                        child: Icon(
                                          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isExpense ? AppColors.expense : AppColors.income,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(transaction.categoryName ?? 'Danh mục', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(transaction.amount), style: TextStyle(color: isExpense ? AppColors.expense : AppColors.income, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(DateFormat('dd/MM/yyyy').format(transaction.date), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                      padding: const EdgeInsets.only(bottom: 120),
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
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

          // Bottom navigation and FAB area handled in Stack below so it overlaps content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small spacing above bottom nav
                const SizedBox(height: 6),
                // Bottom navigation
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomItem(0, Icons.grid_view, 'Tổng hợp'),
                      _buildBottomItem(1, Icons.pie_chart_outline, 'Thống kê'),
                      const SizedBox(width: 48), // Space for FAB
                      _buildBottomItem(2, Icons.calendar_today, 'Lịch'),
                      _buildBottomItem(3, Icons.person_outline, 'Tài khoản'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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


  Widget _buildBottomItem(int index, IconData icon, String label) {
    final isSelected = _selectedBottomIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedBottomIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
