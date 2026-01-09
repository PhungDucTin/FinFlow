import 'dart:math'; // Thêm thư viện Toán học để tính Max
import 'package:finflow/configs/constants.dart';
import 'package:finflow/services/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenseStats = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;

    setState(() => _isLoading = true);

    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
      23,
      59,
      59,
    ); // Cuối ngày cuối tháng

    // ... (Code cũ lấy Pie/Bar chart giữ nguyên) ...
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

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _loadData();
  }

  // Hàm chọn tháng nhanh bằng lịch
  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "CHỌN THÁNG CẦN XEM",
      // Mẹo: Dùng DatePicker mặc định, người dùng chọn ngày bất kỳ trong tháng là được
    );
    if (picked != null && picked != _currentMonth) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
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
    final monthText = DateFormat('MM/yyyy').format(_currentMonth);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Thêm màu nền xám nhẹ cho sạch
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
                // Cho phép kéo xuống để reload
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 1. THANH CHỌN THÁNG ---
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
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.grey,
                              ),
                            ),
                            GestureDetector(
                              onTap: _pickMonth, // Cho phép ấn vào để chọn lịch
                              child: Column(
                                children: [
                                  const Text(
                                    'Thời gian',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        monthText,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- 2. TỔNG QUAN THU CHI ---
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
                              ), // Đường kẻ dọc
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

                      // --- 3. BIỂU ĐỒ TRÒN (CƠ CẤU CHI TIÊU) ---
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
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // FIX: Tăng chiều cao lên 300 để không bị cắt hình
                            SizedBox(
                              height: 300,
                              child: _expenseStats.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Chưa có chi tiêu trong tháng này',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    )
                                  : PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40, // Lỗ tròn ở giữa
                                        startDegreeOffset:
                                            -90, // Xoay để bắt đầu từ đỉnh
                                        sections: _buildPieSections(),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            // Chú thích (Legend)
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: _expenseStats.map((e) {
                                final color = _colorFromHex(e['color_hex']);
                                final name = e['name'] as String;
                                final total = (e['total'] as num).toDouble();
                                final percent = _totalExpense > 0
                                    ? (total / _totalExpense * 100)
                                          .toStringAsFixed(1)
                                    : "0";

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: color,
                                        radius: 5,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "($percent%)",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- 4. BIỂU ĐỒ CỘT (SO SÁNH) ---
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
                        height: 250,
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          32,
                          16,
                          16,
                        ), // Padding top nhiều hơn để chừa chỗ cho label cột
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                max(_totalIncome, _totalExpense) *
                                1.2, // FIX: Tính Max Y + 20% đệm để cột không đụng nóc
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
                                  reservedSize:
                                      40, // <--- THÊM DÒNG NÀY (Tăng khoảng trống đáy lên 40px)
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

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

  // Hàm tạo Cột biểu đồ nâng cao (Có nền xám phía sau)
  BarChartGroupData _buildBarGroup(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30, // FIX: Cột to hơn (30px)
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY * 1.2, // Chiều cao cột nền
            color: Colors.grey.withValues(alpha: 0.1), // Màu nền xám nhạt
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

    return _expenseStats.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = (data['total'] as num).toDouble();
      final percent = (value / total * 100);
      final color = _colorFromHex(data['color_hex']);

      // FIX: Chỉ hiện Text % trên biểu đồ nếu miếng đó lớn hơn 5%
      final isLargeEnough = percent > 5;

      return PieChartSectionData(
        color: color,
        value: value,
        title: isLargeEnough
            ? '${percent.toStringAsFixed(1)}%'
            : '', // Ẩn nếu quá nhỏ
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        radius: isLargeEnough
            ? 100
            : 80, // Miếng to thì lồi ra 1 chút (hiệu ứng 3D nhẹ)
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  List<FlSpot> _generateLineChartData(List<Map<String, dynamic>> rawData) {
    // 1. Tạo Map chứa 30/31 ngày, mặc định giá trị là 0
    Map<int, double> dailyTotals = {};
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;

    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0;
    }

    // 2. Duyệt dữ liệu từ DB và cộng dồn vào ngày tương ứng
    for (var item in rawData) {
      // Giả sử item['date'] là int (milliseconds)
      final date = DateTime.fromMillisecondsSinceEpoch(item['date'] as int);
      final amount = (item['amount'] as num).toDouble();

      if (dailyTotals.containsKey(date.day)) {
        dailyTotals[date.day] = dailyTotals[date.day]! + amount;
      }
    }

    // 3. Chuyển đổi thành điểm (FlSpot) cho biểu đồ
    // X: Ngày (1, 2, 3...), Y: Số tiền
    return dailyTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }
}
