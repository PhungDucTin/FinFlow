import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/database_helper.dart';
import 'package:intl/intl.dart'; // Thư viện để format tiền tệ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Biến lưu danh sách giao dịch
  late Future<List<TransactionModel>> _transactionList;

  @override
  void initState() {
    super.initState();
    // Gọi hàm lấy dữ liệu từ Database khi màn hình mở lên
    _refreshTransactions();
  }

  // Hàm lấy lại dữ liệu mới nhất từ SQLite
  void _refreshTransactions() {
    setState(() {
      _transactionList = DatabaseHelper.instance.getAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FinFlow", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00796B), // Màu xanh Teal
        centerTitle: true,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionList, // Chờ dữ liệu từ Database
        builder: (context, snapshot) {
          // 1. Trạng thái đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Nếu có lỗi
          else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          // 3. Nếu chưa có dữ liệu (Danh sách rỗng)
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có giao dịch nào.\nBấm + để thêm mới.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 4. Có dữ liệu -> Hiển thị danh sách
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final transaction = snapshot.data![index];
              final isExpense = transaction.type == 'expense';
              final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
                    child: Icon(
                      isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    transaction.categoryName ?? 'Giao dịch',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(transaction.note.isNotEmpty ? transaction.note : 'Không có ghi chú'),
                  trailing: Text(
                    formatter.format(transaction.amount),
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Nút thêm giao dịch (Sẽ xử lý sau)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Chuyển sang màn hình thêm giao dịch");
        },
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}