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
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // --- LOGIC MỚI: KIỂM TRA CHẾ ĐỘ SỬA ---
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      
      // 1. Điền dữ liệu vào Controller
      _amountController.text = t.amount % 1 == 0 
          ? t.amount.toInt().toString() 
          : t.amount.toString();
      _noteController.text = t.note;
      
      // 2. Điền biến trạng thái
      _selectedCategoryId = t.categoryId; 

      // 3. Chuyển đúng Tab (Expense/Income)
      // FIX LỖI: Tạo biến trung gian để xử lý trường hợp t.type bị null
      String currentType = t.type ?? 'expense'; // Nếu null thì mặc định là 'expense'
      
      int initialIndex = currentType == 'expense' ? 0 : 1;
      _tabController.index = initialIndex; 
      
      _loadCategories(currentType); // Truyền biến đã xử lý null vào đây
    } else {
      // Chế độ Thêm mới
      _loadCategories('expense');
    }
    // ----------------------------------------

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
      // QUAN TRỌNG: Chỉ reset selectedId về null nếu đang THÊM MỚI.
      // Nếu đang SỬA, phải giữ nguyên ID để biết mà bật modal.
      if (widget.transactionToEdit == null) {
        _selectedCategoryId = null;
      }
      _isLoading = false;
    });

    // --- LOGIC MỚI: TỰ ĐỘNG BẬT MODAL NẾU ĐANG SỬA ---
    if (widget.transactionToEdit != null && _selectedCategoryId != null) {
      // 1. Tìm object Category tương ứng với ID đang sửa
      try {
        final currentCategory = cats.firstWhere((c) => c.id == _selectedCategoryId);
        
        // 2. Đợi UI render xong frame hiện tại rồi mới bật Modal
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) { // Kiểm tra xem màn hình còn tồn tại không
             List<String> notes = await DatabaseHelper.instance.getUniqueNotesByCategory(currentCategory.id!);
            _showNumericKeyboard(currentCategory, notes);
          }
        });
      } catch (e) {
        // Không tìm thấy danh mục tương ứng
      }
    }
  }

  void _showNumericKeyboard(CategoryModel category, List<String> suggestions) {
    final stateContext = context;
    final walletBalance = context.read<TransactionProvider>().walletBalance;
    final TextEditingController noteModalController = TextEditingController(text: _noteController.text);
    FocusNode notesFocusNode = FocusNode();

    String formatCurrencyVN(String amount) {
      if (amount.isEmpty) return "0";
      return amount.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
    }

    showModalBottomSheet(
      context: stateContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          expand: false,
          snap: true,  // Snap to heights để tránh co lại thường xuyên
          snapSizes: const [0.5, 0.95], // Snap points: min hoặc full height
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF065B4C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                SizedBox(height: ResponsiveSize.getPadding(context, 12)),
                // HEADER (Ví & Danh mục & Close)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getPadding(context, 20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: ResponsiveSize.getIconSize(context, 28),
                          ),
                          Text(
                            "${formatCurrencyVN(walletBalance.toInt().toString())} đ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveSize.getFontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: ResponsiveSize.getIconSize(context, 32),
                            child: Icon(
                              getIconByKey(category.iconKey),
                              color: Colors.white,
                              size: ResponsiveSize.getIconSize(context, 36),
                            ),
                          ),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveSize.getFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: ResponsiveSize.getIconSize(context, 28),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // HIỂN THỊ SỐ TIỀN LỚN - Hiển thị đầy đủ không bị cắt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      _amountController.text.isEmpty ? "0 đ" : "${formatCurrencyVN(_amountController.text)} đ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _calculateDynamicAmountFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getPadding(context, 24)),

                // TRƯỜNG GHI CHÚ
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getPadding(context, 16)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: TextField(
                      focusNode: notesFocusNode,
                      controller: noteModalController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveSize.getFontSize(context, 16),
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: "Ghi chú",
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: ResponsiveSize.getFontSize(context, 16),
                        ),
                        prefixIcon: Icon(
                          Icons.edit_note,
                          color: Colors.white70,
                          size: ResponsiveSize.getIconSize(context, 24),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.getPadding(context, 14),
                          horizontal: ResponsiveSize.getPadding(context, 12),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {});
                      },
                      onSubmitted: (_) {
                        notesFocusNode.unfocus();
                      },
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getPadding(context, 8)),

                // GỢI Ý GHI CHÚ
                if (suggestions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getPadding(context, 16),
                      vertical: ResponsiveSize.getPadding(context, 8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: suggestions.take(3).map((note) => GestureDetector(
                          onTap: () => setModalState(() => noteModalController.text = note),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: ResponsiveSize.getPadding(context, 8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSize.getPadding(context, 14),
                              vertical: ResponsiveSize.getPadding(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30, width: 1),
                            ),
                            child: Text(
                              note,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveSize.getFontSize(context, 13),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                SizedBox(height: ResponsiveSize.getPadding(context, 12)),

                // GIỜ VÀ NGÀY THÁNG
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getPadding(context, 16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: ResponsiveSize.getIconSize(context, 18),
                          ),
                          SizedBox(width: ResponsiveSize.getPadding(context, 6)),
                          Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveSize.getFontSize(context, 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveSize.getFontSize(context, 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: ResponsiveSize.getPadding(context, 6)),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: ResponsiveSize.getIconSize(context, 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getPadding(context, 12)),
                
                // NÚT SỐ TIỀN NHANH
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getPadding(context, 16),
                    vertical: ResponsiveSize.getPadding(context, 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["5000", "10000", "50000"].map((val) => Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: ResponsiveSize.getPadding(context, 4)),
                        child: OutlinedButton(
                          onPressed: () => setModalState(() => _amountController.text = val),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38, width: 1.5),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveSize.getPadding(context, 12),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            formatCurrencyVN(val),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveSize.getFontSize(context, 13),
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),

                // BÀN PHÍM SỐ
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10, width: 1)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 2, child: _buildGridKey("AC", setModalState)),
                              Expanded(flex: 1, child: _buildGridKeyIcon(Icons.backspace_outlined, setModalState)),
                            ],
                          ),
                        ),
                        Expanded(child: _buildRowKey(["1", "2", "3"], setModalState)),
                        Expanded(child: _buildRowKey(["4", "5", "6"], setModalState)),
                        Expanded(child: _buildRowKey(["7", "8", "9"], setModalState)),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildGridKey("000", setModalState)),
                              Expanded(child: _buildGridKey("0", setModalState)),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _noteController.text = noteModalController.text;
                                    Navigator.pop(context);
                                    _saveTransaction();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      border: Border.all(color: Colors.white10, width: 1),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFBC02D), 
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Color(0xFF065B4C), size: 26),
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
                ),
              ],
            ),
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

  Widget _buildGridKey(String label, Function setModalState, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: TextButton(
        onPressed: () {
          setModalState(() {
            if (label == "AC") {
              _amountController.clear();
            } else if (_amountController.text.length < 12) {
              // Giới hạn tối đa 12 chữ số (999.999.999.999)
              _amountController.text += label;
            }
          });
          setState(() {});
        },
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveSize.getFontSize(context, 26),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildGridKeyIcon(IconData icon, Function setModalState, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: ResponsiveSize.getIconSize(context, 26),
        ),
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transactionData = TransactionModel(
      id: widget.transactionToEdit?.id, // <--- GIỮ ID CŨ NẾU SỬA
      userId: user.uid,
      amount: amount,
      note: _noteController.text,
      date: widget.transactionToEdit != null ? widget.transactionToEdit!.date : _selectedDate, // Giữ ngày cũ nếu sửa
      categoryId: _selectedCategoryId!,
      type: _tabController.index == 0 ? 'expense' : 'income',
    );

    if (widget.transactionToEdit == null) {
      // THÊM MỚI
      context.read<TransactionProvider>().addTransaction(transactionData);
    } else {
      // CẬP NHẬT
      context.read<TransactionProvider>().updateTransaction(transactionData);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null ? "Thêm giao dịch" : "Sửa giao dịch",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveSize.getFontSize(context, 20),
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveSize.getFontSize(context, 16),
          ),
          tabs: const [Tab(text: "CHI TIÊU"), Tab(text: "THU NHẬP")],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Chỉ hiển thị danh mục - phần tiền, ghi chú, ngày tháng đã hiển thị trong modal
            Padding(
              padding: EdgeInsets.all(ResponsiveSize.getPadding(context, 16)),
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getResponsiveColumnCount(context),
                      childAspectRatio: ResponsiveSize.getGridAspectRatio(context, _getResponsiveColumnCount(context)),
                      crossAxisSpacing: ResponsiveSize.getPadding(context, 15),
                      mainAxisSpacing: ResponsiveSize.getPadding(context, 15),
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
                            color: catColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? Border.all(color: catColor, width: 2.5) : null,
                            boxShadow: isSelected ? [BoxShadow(color: catColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
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

  // Cố định font size sao cho vừa đủ số tiền tối đa 999.999.999.999
  // Max 12 chữ số + 3 dấu chấm = 15 ký tự, font size ~36px để vừa không bị tràn
  double _calculateDynamicAmountFontSize(BuildContext context) {
    // Sử dụng font size cố định 36px sao cho 999.999.999.999 vừa đủ
    return ResponsiveSize.getFontSize(context, 36);
  }

  int _getResponsiveColumnCount(BuildContext context) {
    final deviceType = ResponsiveSize.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }
}
