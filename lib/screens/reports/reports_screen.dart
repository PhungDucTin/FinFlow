import 'dart:math'; // Để dùng hàm max()
import 'package:finflow/configs/constants.dart';
import 'package:finflow/services/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Định nghĩa các loại báo cáo
enum ReportType { day, week, month }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Dùng _selectedDate làm mốc thời gian duy nhất
  DateTime _selectedDate = DateTime.now();
  ReportType _currentType = ReportType.month; // Mặc định xem theo Tháng

  bool _isLoading = true;
  List<Map<String, dynamic>> _expenseStats = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Hàm tải dữ liệu (Logic chuẩn cho Ngày/Tuần/Tháng)
  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    setState(() => _isLoading = true);

    DateTime start;
    DateTime end;

    // --- LOGIC TÍNH THỜI GIAN ---
    if (_currentType == ReportType.day) {
      // Ngày: 00:00:00 -> 23:59:59
      start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
        59,
      );
    } else if (_currentType == ReportType.week) {
      // Tuần: Thứ 2 -> Chủ Nhật
      // weekday: 1 (Mon) -> 7 (Sun)
      DateTime monday = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      start = DateTime(monday.year, monday.month, monday.day);

      DateTime sunday = monday.add(const Duration(days: 6));
      end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    } else {
      // Tháng: Ngày 1 -> Ngày cuối tháng
      start = DateTime(_selectedDate.year, _selectedDate.month, 1);
      end = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
        23,
        59,
        59,
      );
    }

    // --- GỌI DATABASE ---
    final expenseStats = await DatabaseHelper.instance.getCategoryStats(
      'expense',
      start,
      end,
      userId,
    );
    final totalIncome = await DatabaseHelper.instance.calculateTotal(
      'income',
      start,
      end,
      userId,
    );
    final totalExpense = await DatabaseHelper.instance.calculateTotal(
      'expense',
      start,
      end,
      userId,
    );

    if (!mounted) return;
    setState(() {
      _expenseStats = expenseStats;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Ngày đang chọn
      firstDate: DateTime(2020), // Ngày bắt đầu cho phép chọn
      lastDate: DateTime(2030), // Ngày kết thúc cho phép chọn
      locale: const Locale('vi', 'VN'), // Hiển thị tiếng Việt (nếu đã cấu hình)
      helpText: _currentType == ReportType.month
          ? 'CHỌN MỘT NGÀY BẤT KỲ TRONG THÁNG' // Hướng dẫn nếu đang xem theo tháng
          : 'CHỌN NGÀY',
      builder: (context, child) {
        // Tùy chỉnh màu sắc lịch cho đồng bộ với App
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary, // Màu đầu lịch
              onPrimary: Colors.white, // Màu chữ trên đầu lịch
              onSurface: Colors.black, // Màu số ngày
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Màu nút OK/Cancel
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData(); // Tải lại dữ liệu theo ngày mới chọn
    }
  }

  // Hàm thay đổi thời gian (Tăng/Giảm)
  void _changeTime(int delta) {
    setState(() {
      if (_currentType == ReportType.day) {
        _selectedDate = _selectedDate.add(Duration(days: delta));
      } else if (_currentType == ReportType.week) {
        _selectedDate = _selectedDate.add(Duration(days: delta * 7));
      } else {
        // Cộng trừ tháng
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + delta,
          1,
        );
      }
    });
    _loadData();
  }

  // Hàm hiển thị Label thời gian
  String _getDateLabel() {
    if (_currentType == ReportType.day) {
      return DateFormat('dd/MM/yyyy').format(_selectedDate);
    } else if (_currentType == ReportType.week) {
      DateTime monday = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      DateTime sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('dd/MM').format(monday)} - ${DateFormat('dd/MM/yyyy').format(sunday)}';
    } else {
      return DateFormat('MM/yyyy').format(_selectedDate);
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // Đã xóa dòng "final monthText = ..." gây lỗi
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Báo cáo thống kê',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 1. THANH CHỌN TAB (Ngày | Tuần | Tháng) ---
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton("Ngày", ReportType.day),
                            _buildTabButton("Tuần", ReportType.week),
                            _buildTabButton("Tháng", ReportType.month),
                          ],
                        ),
                      ),

                      // --- 2. THANH ĐIỀU HƯỚNG THỜI GIAN ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _changeTime(-1),
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                              ),
                            ),
                            GestureDetector(
                              onTap: _selectDate, // Gọi hàm mở lịch khi bấm
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(
                                    0.1,
                                  ), // Thêm nền nhẹ cho đẹp
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 18,
                                      color: AppColors.primary,
                                    ), // Thêm icon lịch
                                    const SizedBox(width: 8),
                                    Text(
                                      _getDateLabel(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.primary,
                                    ), // Icon mũi tên nhỏ báo hiệu dropdown
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _changeTime(1),
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- 3. TỔNG QUAN THU CHI ---
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryItem(
                                  'Thu nhập',
                                  _totalIncome,
                                  AppColors.income,
                                  currencyFormatter,
                                  Icons.arrow_downward,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _buildSummaryItem(
                                  'Chi tiêu',
                                  _totalExpense,
                                  AppColors.expense,
                                  currencyFormatter,
                                  Icons.arrow_upward,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 4. BIỂU ĐỒ TRÒN ---
                      Text(
                        'Cơ cấu chi tiêu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 300,
                              child: _expenseStats.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Chưa có chi tiêu',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    )
                                  : PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        startDegreeOffset: -90,
                                        sections: _buildPieSections(),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            // Chú thích (Legend)
                            if (_expenseStats.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _expenseStats.map((e) {
                                  final color = _colorFromHex(e['color_hex']);
                                  final name = e['name'] as String;
                                  final total = (e['total'] as num).toDouble();
                                  final percent = _totalExpense > 0
                                      ? (total / _totalExpense * 100)
                                            .toStringAsFixed(1)
                                      : "0";
                                  return Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: color,
                                      radius: 5,
                                    ),
                                    label: Text(
                                      "$name ($percent%)",
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: color.withOpacity(0.1),
                                    side: BorderSide.none,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- 5. BIỂU ĐỒ CỘT SO SÁNH ---
                      Text(
                        'So sánh Thu - Chi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: max(_totalIncome, _totalExpense) == 0
                                ? 1000000
                                : max(_totalIncome, _totalExpense) * 1.2,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.blueGrey,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        currencyFormatter.format(rod.toY),
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        value.toInt() == 0
                                            ? 'Thu nhập'
                                            : 'Chi tiêu',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: value.toInt() == 0
                                              ? AppColors.income
                                              : AppColors.expense,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: [
                              _buildBarGroup(
                                0,
                                _totalIncome,
                                AppColors.income,
                                max(_totalIncome, _totalExpense),
                              ),
                              _buildBarGroup(
                                1,
                                _totalExpense,
                                AppColors.expense,
                                max(_totalIncome, _totalExpense),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- WIDGET CON & HELPER ---

  Widget _buildSummaryItem(
    String title,
    double amount,
    Color color,
    NumberFormat formatter,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color, double maxY) {
    double effectiveMaxY = maxY == 0 ? 100 : maxY;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: effectiveMaxY * 1.2,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = _expenseStats.fold<double>(
      0,
      (prev, e) => prev + (e['total'] as num).toDouble(),
    );
    if (total == 0) return [];

    return _expenseStats.map((data) {
      final value = (data['total'] as num).toDouble();
      final percent = (value / total * 100);
      final color = _colorFromHex(data['color_hex']);
      final isLargeEnough = percent > 5;

      return PieChartSectionData(
        color: color,
        value: value,
        title: isLargeEnough ? '${percent.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: isLargeEnough ? 100 : 80,
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildTabButton(String title, ReportType type) {
    final isSelected = _currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentType = type;
            _selectedDate = DateTime.now();
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
