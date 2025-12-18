import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  // Danh sách giao dịch hiển thị trên UI
  List<TransactionModel> _transactions = [];

  // Các biến thống kê cho Dashboard
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;

  //Getter để UI lấy dữ liệu
  List<TransactionModel> get transactions => _transactions;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;

  // 1. Hàm tải dữ liệu ban đầu (Gọi khi mở app)
  Future<void> loadData() async {
    await loadTransactionsByMonth(DateTime.now());
  }

  // 2. Tải giao dịch theo tháng (Dùng cho Dashboard và Lịch)
  Future<void> loadTransactionsByMonth(DateTime date) async {
    // Gọi DatabaseHelper
    _transactions = await DatabaseHelper.instance.getTransactionsByMonth(
      date.month,
      date.year,
    );

    // Tính toán lại tổng tiền ngay sau khi lấy dữ liệu
    await _calculateBudget(date);

    // Báo cho UI cập nhật
    notifyListeners();
  }

  // 3. Thêm giao dịch mới
  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    // Reload lại dữ liệu tháng hiện tại để Dashboard cập nhật ngay
    await loadTransactionsByMonth(transaction.date);
  }

  // 4. Xoá giao dịch
  Future<void> deleteTransaction(int id, DateTime currentDate) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactionsByMonth(currentDate);
  }

  // Hàm nội bộ: Tính toán thu/ chi/ số dư
  Future<void> _calculateBudget(DateTime date) async {
    // Lấy ngày đầu và cuối tháng
    DateTime start = DateTime(date.year, date.month, 1);
    DateTime end = DateTime(date.year, date.month + 1, 0);

    // Gọi hàm calculateTotal từ DatabaseHelper
    _totalIncome = await DatabaseHelper.instance.calculateTotal(
      'income',
      start,
      end,
    );
    _totalExpense = await DatabaseHelper.instance.calculateTotal(
      'expense',
      start,
      end,
    );
    _balance = _totalIncome - _totalExpense;
  }
}
