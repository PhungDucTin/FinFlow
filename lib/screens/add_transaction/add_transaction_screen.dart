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
    _loadCategories('expense'); // Mặc định load danh mục Chi tiêu

    // Lắng nghe khi chuyển Tab (Chi tiêu <-> Thu nhập)
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final type = _tabController.index == 0 ? 'expense' : 'income';
        _loadCategories(type);
      }
    });
  }

  // Hàm lấy danh mục từ Database
  void _loadCategories(String type) async {
    setState(() => _isLoading = true);
    final cats = await DatabaseHelper.instance.getCategoriesByType(type);
    setState(() {
      _categories = cats;
      _selectedCategoryId = null; // Reset chọn khi đổi tab
      _isLoading = false;
    });
  }

  // Hàm Lưu Giao Dịch
  void _saveTransaction() {
    if (_amountController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tiền và chọn danh mục")),
      );
      return;
    }

    // Xử lý số tiền (Xóa dấu chấm/phẩy nếu có)
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final type = _tabController.index == 0 ? 'expense' : 'income';

    final newTransaction = TransactionModel(
      amount: amount,
      note: _noteController.text,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      type: type,
    );

    // Gọi Provider để lưu và cập nhật Dashboard
    context.read<TransactionProvider>().addTransaction(newTransaction);

    Navigator.pop(context); // Đóng màn hình
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm giao dịch", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: "CHI TIÊU"),
            Tab(text: "THU NHẬP"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Nhập tiền và Ghi chú
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: "Số tiền",
                    suffixText: "đ",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: "Ghi chú (vd: Ăn sáng)",
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Chọn ngày
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(DateFormat('dd/MM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),

          // 2. Lưới danh mục
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 cột
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat.id == _selectedCategoryId;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)]
                                    : [],
                              ),
                              child: Icon(
                                // Tạm thời dùng icon mặc định, bạn có thể map iconKey sang IconData sau
                                Icons.category, 
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Nút Lưu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("LƯU", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}