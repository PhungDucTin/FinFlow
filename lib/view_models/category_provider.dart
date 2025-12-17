import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  Future<void> loadAll() async {
    _categories = await DatabaseHelper.instance.getAllCategories();
    notifyListeners();
  }

  Future<List<CategoryModel>> getByType(String type) async {
    return await DatabaseHelper.instance.getCategoriesByType(type);
  }

  Future<int> addCategory(CategoryModel category) async {
    final id = await DatabaseHelper.instance.insertCategory(category);
    await loadAll();
    return id;
  }

  Future<void> deleteCategory(int id) async {
    // TODO: handle transactions referencing this category (reassign or block)
    await DatabaseHelper.instance.deleteCategory(id);
    await loadAll();
  }
}
