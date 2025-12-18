import 'package:finflow/configs/constants.dart';
import 'package:finflow/services/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    setState(() => _isLoading = true);
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Thống kê chi tiêu theo danh mục
    final expenseStats = await DatabaseHelper.instance.getCategoryStats(
      'expense',
      start,
      end,
    );

    // Tổng thu / chi
    final totalIncome = await DatabaseHelper.instance.calculateTotal(
      'income',
      start,
      end,
    );
    final totalExpense = await DatabaseHelper.instance.calculateTotal(
      'expense',
      start,
      end,
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
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
      );
    });
    _loadData();
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
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Báo cáo thống kê',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chọn tháng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Tháng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        monthText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Tổng thu / chi
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Thu nhập',
                          _totalIncome,
                          AppColors.income,
                          currencyFormatter,
                        ),
                        _buildSummaryItem(
                          'Chi tiêu',
                          _totalExpense,
                          AppColors.expense,
                          currencyFormatter,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Biểu đồ tròn chi tiêu theo danh mục
                        Text(
                          'Cơ cấu chi tiêu theo danh mục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: _expenseStats.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Chưa có dữ liệu chi tiêu trong tháng',
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _buildPieSections(),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        // Chú thích danh mục
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _expenseStats.map((e) {
                            final color = _colorFromHex(e['color_hex']);
                            final name = e['name'] as String;
                            final total = (e['total'] as num).toDouble();
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: color,
                              ),
                              label: Text(
                                '$name (${currencyFormatter.format(total)})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Biểu đồ cột so sánh Thu / Chi
                        Text(
                          'So sánh Thu nhập / Chi tiêu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
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
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Thu nhập');
                                        case 1:
                                          return const Text('Chi tiêu');
                                        default:
                                          return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _totalIncome,
                                      color: AppColors.income,
                                      width: 25,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _totalExpense,
                                      color: AppColors.expense,
                                      width: 25,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
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
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
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
      final percent = (value / total * 100).toStringAsFixed(1);
      final color = _colorFromHex(data['color_hex']);

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$percent%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 60 + (index % 3) * 4,
      );
    }).toList();
  }
}


