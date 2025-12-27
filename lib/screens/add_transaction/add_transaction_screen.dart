import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/database_helper.dart';
import '../../view_models/transaction_provider.dart';
import '../../configs/constants.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories('expense');

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final type = _tabController.index == 0 ? 'expense' : 'income';
        _loadCategories(type);
      }
    });
  }

  void _loadCategories(String type) async {
    setState(() => _isLoading = true);
    final cats = await DatabaseHelper.instance.getCategoriesByType(type);
    setState(() {
      _categories = cats;
      _selectedCategoryId = null;
      _isLoading = false;
    });
  }

  // --- 1. GIAO DIỆN BÀN PHÍM SỐ (Numeric Keypad) 
void _showNumericKeyboard(CategoryModel category, List<String> suggestions) {
  final walletBalance = context.read<TransactionProvider>().walletBalance;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.85, 
        decoration: const BoxDecoration(
          color: Color(0xFF065B4C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // HEADER (Ví & Danh mục) - Giữ nguyên
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      Text("${walletBalance.toInt()} đ", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(getIconByKey(category.iconKey), color: Colors.white),
                      ),
                      Text(category.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white70, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // HIỂN THỊ SỐ TIỀN LỚN
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                _amountController.text.isEmpty ? "0 đ" : "${_amountController.text} đ",
                style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold),
              ),
            ),

            // --- ĐÃ XÓA PHẦN GHI CHÚ GỢI Ý (WRAP) TẠI ĐÂY THEO YÊU CẦU ---

            const Spacer(), // Đẩy bàn phím xuống đáy
            
            // NÚT SỐ TIỀN NHANH (5k, 10k, 50k)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["5,000", "10,000", "50,000"].map((val) => OutlinedButton(
                  onPressed: () => setModalState(() => _amountController.text = val.replaceAll(',', '')),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  child: Text(val, style: const TextStyle(color: Colors.white)),
                )).toList(),
              ),
            ),

            // --- BÀN PHÍM ĐÃ FIX LỖI KHOẢNG TRỐNG ---
            // Sử dụng Column + Row thay vì GridView để tùy biến độ rộng nút AC
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
              ),
              // Chiều cao cố định cho bàn phím để không bị lỗi layout
              height: MediaQuery.of(context).size.height * 0.45, 
              child: Column(
                children: [
                  // Hàng 1: AC (chiếm 2 phần) và Backspace (chiếm 1 phần)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: _buildGridKey("AC", setModalState)), // AC dài gấp đôi
                        Expanded(flex: 1, child: _buildGridKeyIcon(Icons.backspace_outlined, setModalState)),
                      ],
                    ),
                  ),
                  // Hàng 2: 1 - 2 - 3
                  Expanded(child: _buildRowKey(["1", "2", "3"], setModalState)),
                  // Hàng 3: 4 - 5 - 6
                  Expanded(child: _buildRowKey(["4", "5", "6"], setModalState)),
                  // Hàng 4: 7 - 8 - 9
                  Expanded(child: _buildRowKey(["7", "8", "9"], setModalState)),
                  // Hàng 5: 000 - 0 - Check
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildGridKey("000", setModalState)),
                        Expanded(child: _buildGridKey("0", setModalState)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _saveTransaction();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(color: Colors.white10, width: 0.5),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFFBC02D), shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Color(0xFF065B4C), size: 28),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRowKey(List<String> keys, Function setModalState) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: keys.map((k) => Expanded(child: _buildGridKey(k, setModalState))).toList(),
  );
}

Widget _buildQuickTag(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Text(label, style: const TextStyle(color: Color(0xFF004D40), fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

// Widget cho các nút số tiền nhanh (5k, 10k...)
Widget _buildQuickAmount(String amount, Function setModalState) {
  return GestureDetector(
    onTap: () {
      setModalState(() => _amountController.text = amount.replaceAll(',', ''));
      setState(() {});
    },
    child: Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ),
  );
}

// Hàm xây dựng phím bấm có kẻ khung Grid (Border)
Widget _buildGridKey(String label, Function setModalState, {Color? color}) {
  return Container(
    decoration: BoxDecoration(
      color: color ?? Colors.white.withOpacity(0.05),
      border: Border.all(color: Colors.white10, width: 0.5), // Đường kẻ lưới
    ),
    child: TextButton(
      onPressed: () {
        setModalState(() {
          if (label == "AC") _amountController.clear();
          else _amountController.text += label;
        });
        setState(() {});
      },
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w400)),
    ),
  );
}

// Widget phím Icon (Xóa) có kẻ khung
Widget _buildGridKeyIcon(IconData icon, Function setModalState, {Color? color}) {
  return Container(
    decoration: BoxDecoration(
      color: color ?? Colors.white.withOpacity(0.05),
      border: Border.all(color: Colors.white10, width: 0.5),
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white, size: 26),
      onPressed: () {
        setModalState(() {
          if (_amountController.text.isNotEmpty) {
            _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
          }
        });
        setState(() {});
      },
    ),
  );
}

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tiền và chọn danh mục")));
      return;
    }
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newTransaction = TransactionModel(
      userId: user.uid,
      amount: amount,
      note: _noteController.text,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      type: _tabController.index == 0 ? 'expense' : 'income',
    );
    context.read<TransactionProvider>().addTransaction(newTransaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt cho nổi Card
      appBar: AppBar(
        title: const Text("Thêm giao dịch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [Tab(text: "CHI TIÊU"), Tab(text: "THU NHẬP")],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    onTap: () async {
                      if (_selectedCategoryId != null) {
                        final category = _categories.firstWhere((c) => c.id == _selectedCategoryId);
                        List<String> notes = await DatabaseHelper.instance.getUniqueNotesByCategory(category.id!);
                        _showNumericKeyboard(category, notes);
                      }
                    },
                    style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(hintText: "0", suffixText: "đ", border: InputBorder.none),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(hintText: "Ghi chú...", border: InputBorder.none, prefixIcon: Icon(Icons.edit_note)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        icon: const Icon(Icons.calendar_month, size: 20),
                        label: Text(DateFormat('dd/MM').format(_selectedDate)),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            // --- 2. GIAO DIỆN DANH MỤC 3 CỘT PASTEL GIỐNG ẢNH 847 ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.88,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat.id == _selectedCategoryId;
                      final catColor = getColorFromHex(cat.colorHex);

                      return GestureDetector(
                        onTap: () async {
                          setState(() => _selectedCategoryId = cat.id);
                          List<String> notes = await DatabaseHelper.instance.getUniqueNotesByCategory(cat.id!);
                          _showNumericKeyboard(cat, notes);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.18), // Màu pastel nhẹ
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? Border.all(color: catColor, width: 2.5) : null,
                            boxShadow: isSelected ? [BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(getIconByKey(cat.iconKey), size: 48, color: catColor),
                              const SizedBox(height: 10),
                              Text(
                                cat.name,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}