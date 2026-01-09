import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/database_helper.dart';
import '../../configs/constants.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  void _loadCategories() async {
    setState(() => _isLoading = true);
    final expenses = await DatabaseHelper.instance.getCategoriesByType('expense');
    final incomes = await DatabaseHelper.instance.getCategoriesByType('income');
    
    setState(() {
      _expenseCategories = expenses;
      _incomeCategories = incomes;
      _isLoading = false;
    });
  }

  void _showCategoryOptionsBottomSheet(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCategory(category);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Xoá'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    String selectedIcon = 'food';
    String selectedColorKey = 'Cam'; // Khóa của màu, không phải hex

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên danh mục
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục',
                    hintText: 'Ví dụ: Quần áo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (tuỳ chọn)',
                    hintText: 'Ví dụ: Quần áo, giày dép...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Chọn Icon
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Chọn Icon',
                    border: OutlineInputBorder(),
                  ),
                  items: _getIconOptions().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(entry.value, size: 20),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedIcon = value ?? selectedIcon);
                  },
                ),
                const SizedBox(height: 16),

                // Chọn Màu
                DropdownButtonFormField<String>(
                  initialValue: selectedColorKey,
                  decoration: const InputDecoration(
                    labelText: 'Chọn màu sắc',
                    border: OutlineInputBorder(),
                  ),
                  items: _getColorOptions().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: entry.value,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedColorKey = value ?? selectedColorKey);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return;
                }

                final colorHex = _colorKeyToHex(selectedColorKey);

                final newCategory = CategoryModel(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  type: _tabController.index == 0 ? 'expense' : 'income',
                  groupName: 'Tùy chỉnh',
                  iconKey: selectedIcon,
                  colorHex: colorHex,
                );

                await DatabaseHelper.instance.insertCategory(newCategory);
                if (!context.mounted) return;
                _loadCategories();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(
                'Thêm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    final TextEditingController descController = TextEditingController(text: category.description ?? '');
    String selectedIcon = category.iconKey;
    String selectedColorKey = _hexToColorKey(category.colorHex);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa danh mục'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên danh mục
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Chọn Icon
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Chọn Icon',
                    border: OutlineInputBorder(),
                  ),
                  items: _getIconOptions().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(entry.value, size: 20),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedIcon = value ?? selectedIcon);
                  },
                ),
                const SizedBox(height: 16),

                // Chọn Màu
                DropdownButtonFormField<String>(
                  initialValue: selectedColorKey,
                  decoration: const InputDecoration(
                    labelText: 'Chọn màu sắc',
                    border: OutlineInputBorder(),
                  ),
                  items: _getColorOptions().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: entry.value,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedColorKey = value ?? selectedColorKey);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return;
                }

                final colorHex = _colorKeyToHex(selectedColorKey);

                final updatedCategory = CategoryModel(
                  id: category.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  type: category.type,
                  groupName: category.groupName,
                  iconKey: selectedIcon,
                  colorHex: colorHex,
                );

                await DatabaseHelper.instance.updateCategory(updatedCategory);
                if (!context.mounted) return;
                _loadCategories();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật danh mục')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(
                'Cập nhật',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá danh mục'),
        content: Text('Bạn có chắc muốn xoá "${category.name}" không?\n\nLưu ý: Các giao dịch sử dụng danh mục này sẽ không bị ảnh hưởng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(category.id!);
              if (!context.mounted) return;
              _loadCategories();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá danh mục')),
              );
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý danh mục',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'CHI TIÊU'),
            Tab(text: 'THU NHẬP'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Chi Tiêu
                _buildCategoryList(_expenseCategories),
                // Tab Thu Nhập
                _buildCategoryList(_incomeCategories),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có danh mục tùy chỉnh',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final catColor = getColorFromHex(category.colorHex);
        final isCustom = category.groupName == 'Tùy chỉnh';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            onTap: isCustom
                ? () => _showCategoryOptionsBottomSheet(category)
                : null,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIconByKey(category.iconKey),
                color: catColor,
                size: 28,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(category.description ?? ''),
            trailing: isCustom
                ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
                : Chip(
                    label: const Text(
                      'Mặc định',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
          ),
        );
      },
    );
  }

  Map<String, IconData> _getIconOptions() {
    return {
      'food': Icons.fastfood,
      'transport': Icons.directions_car,
      'house': Icons.home,
      'bill': Icons.receipt_long,
      'health': Icons.medical_services,
      'coffee': Icons.local_cafe,
      'shopping': Icons.shopping_bag,
      'game': Icons.sports_esports,
      'travel': Icons.flight_takeoff,
      'education': Icons.school,
      'friends': Icons.people,
      'book': Icons.menu_book,
      'party': Icons.celebration,
      'savings': Icons.savings,
      'invest': Icons.trending_up,
      'salary': Icons.account_balance_wallet,
      'part_time': Icons.access_time,
      'other': Icons.category,
    };
  }

  Map<String, Color> _getColorOptions() {
    return {
      'Cam': const Color(0xFFFF9800),
      'Hồng': const Color(0xFFF06292),
      'Xanh dương': const Color(0xFF42A5F5),
      'Xanh ngọc': const Color(0xFF26C6DA),
      'Tím': const Color(0xFFAB47BC),
      'Xanh lá': const Color(0xFF43A047),
      'Vàng': const Color(0xFFFBC02D),
      'Cam đỏ': const Color(0xFFFF7043),
      'Chàm': const Color(0xFF1E88E5),
    };
  }

  String _colorKeyToHex(String key) {
    final colorMap = {
      'Cam': '#FF9800',
      'Hồng': '#F06292',
      'Xanh dương': '#42A5F5',
      'Xanh ngọc': '#26C6DA',
      'Tím': '#AB47BC',
      'Xanh lá': '#43A047',
      'Vàng': '#FBC02D',
      'Cam đỏ': '#FF7043',
      'Chàm': '#1E88E5',
    };
    return colorMap[key] ?? '#FF9800';
  }

  String _hexToColorKey(String hex) {
    final colorMap = {
      '#FF9800': 'Cam',
      '#F06292': 'Hồng',
      '#42A5F5': 'Xanh dương',
      '#26C6DA': 'Xanh ngọc',
      '#AB47BC': 'Tím',
      '#43A047': 'Xanh lá',
      '#FBC02D': 'Vàng',
      '#FF7043': 'Cam đỏ',
      '#1E88E5': 'Chàm',
    };
    return colorMap[hex] ?? 'Cam';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
