import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../view_models/category_provider.dart';
import '../../configs/constants.dart';

// Returns created category id on success, or null if cancelled
Future<int?> showAddCategoryDialog(BuildContext context, {String initialType = 'expense'}) {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController(text: 'Tùy chỉnh');
  String _type = initialType;
  String _iconKey = 'category';
  String _colorHex = '#E0E0E0';

  Color colorFromHex(String hex) => Color(int.parse(hex.replaceAll('#', '0xff')));

  IconData iconFromKey(String key) {
    switch (key) {
      case 'food':
        return Icons.restaurant;
      case 'salary':
        return Icons.attach_money;
      case 'transport':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tạo danh mục mới'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên danh mục'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Chi tiêu')),
                    DropdownMenuItem(value: 'income', child: Text('Thu nhập')),
                  ],
                  onChanged: (v) => _type = v ?? 'expense',
                  decoration: const InputDecoration(labelText: 'Loại'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(labelText: 'Nhóm danh mục'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(backgroundColor: colorFromHex(_colorHex), child: Icon(iconFromKey(_iconKey))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Quick color picker: toggle between a few choices
                        final choices = ['#E0E0E0', '#FFE0B2', '#F8BBD0', '#BBDEFB', '#C8E6C9'];
                        final picked = await showDialog<String>(
                          context: context,
                          builder: (c) => SimpleDialog(
                            title: const Text('Chọn màu'),
                            children: choices
                                .map((h) => SimpleDialogOption(
                                      child: Row(
                                        children: [
                                          CircleAvatar(backgroundColor: colorFromHex(h)),
                                          const SizedBox(width: 8),
                                          Text(h),
                                        ],
                                      ),
                                      onPressed: () => Navigator.pop(c, h),
                                    ))
                                .toList(),
                          ),
                        );
                        if (picked != null) {
                          _colorHex = picked;
                        }
                      },
                      child: const Text('Chọn màu'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final category = CategoryModel(
                name: _nameController.text.trim(),
                description: '',
                type: _type,
                groupName: _groupController.text.trim().isEmpty ? 'Tùy chỉnh' : _groupController.text.trim(),
                iconKey: _iconKey,
                colorHex: _colorHex,
              );
              final provider = context.read<CategoryProvider>();
              final id = await provider.addCategory(category);
              Navigator.pop(context, id);
            },
            child: const Text('Tạo'),
          ),
        ],
      );
    },
  );
}
