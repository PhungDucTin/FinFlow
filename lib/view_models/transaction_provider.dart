import 'package:firebase_auth/firebase_auth.dart';
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

  double _walletBalance = 0.0;

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  //Getter để UI lấy dữ liệu
  List<TransactionModel> get transactions => _transactions;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  double get walletBalance => _walletBalance;

  // 1. Hàm tải dữ liệu ban đầu (Gọi khi mở app)
  Future<void> loadData() async {
    if (_currentUserId.isEmpty) return;
    await _calculateWalletBalance(); // Tính tổng tiền trong ví
    await loadTransactionsByMonth(DateTime.now());
  }

  // 2. Tải giao dịch theo tháng (Dùng cho Dashboard và Lịch)
  Future<void> loadTransactionsByMonth(DateTime date) async {
    if (_currentUserId.isEmpty) return; // Nếu chưa đăng nhập, không tải dữ liệu

    // Gọi DatabaseHelper
    _transactions = await DatabaseHelper.instance.getTransactionsByMonth(
      date.month,
      date.year,
      _currentUserId,
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
    await _calculateWalletBalance();
    await loadTransactionsByMonth(transaction.date);
  }

  // 4. Xoá giao dịch
  Future<void> deleteTransaction(int id, DateTime currentDate) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await _calculateWalletBalance();
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
      _currentUserId,
    );
    _totalExpense = await DatabaseHelper.instance.calculateTotal(
      'expense',
      start,
      end,
      _currentUserId,
    );
    _balance = _totalIncome - _totalExpense;
  }

  // Hàm tính tổng số dư ví (Tổng Thu - Tổng Chi toàn thời gian)
  Future<void> _calculateWalletBalance() async {
    // Lấy TOÀN BỘ giao dịch của người dùng từ database
    final allTransactions = await DatabaseHelper.instance.getAllTransactions();
    final userTransactions = allTransactions.where(
      (t) => t.userId == _currentUserId,
    );

    double totalIn = 0;
    double totalOut = 0;

    for (var t in userTransactions) {
      if (t.type == 'income') {
        totalIn += t.amount;
      } else {
        totalOut += t.amount;
      }
    }
    _walletBalance = totalIn - totalOut;
    notifyListeners(); // Báo cho UI cập nhật số tiền ở biểu tượng Ví
  }
}
