import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../configs/constants.dart';

class DatabaseHelper {
  // Tạo Singleton (Chỉ có 1 kết nối duy nhất trong toàn bộ app)
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  //Hàm lấy Database: Nếu có rồi thì dùng, chưa thì tạo mới
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppStrings.dbName);
    return _database!;
  }

  //Hàm khởi tạo Database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // Gọi hàm khi chạy lần đầu tiên
    );
  }

  //Hàm tạo bảng (Chỉ chạy 1 lần duy nhất khi cài app)
  Future _createDB(Database db, int version) async {
    // 1. Tạo bảng Danh mục (Category)
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        group_name TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_hex TEXT NOT NULL  
        )
        ''');
    // 2. Tạo bảng Giao dịch (Transaction)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id Text,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
        )
        ''');

    // 3. Tự động thêm dữ liệu mẫu
    await _seedData(db);
  }

// Hàm nạp dữ liệu mẫu
Future _seedData(Database db) async {
    final List<Map<String, dynamic>> categories = [
      // --- CHI TIÊU (Expense) - NHÓM THIẾT YẾU ---
      {
        'name': 'Ăn uống',
        'description': 'Ăn sáng, trưa, tối...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'food',
        'color_hex': '#FF9800', // Cam đậm (Thay vì #FFE0B2)
      },
      {
        'name': 'Đi lại',
        'description': 'Xăng xe, taxi, bus...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'transport',
        'color_hex': '#F06292', // Hồng đậm
      },
      {
        'name': 'Nhà cửa',
        'description': 'Tiền nhà, điện nước...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'house',
        'color_hex': '#42A5F5', // Xanh dương đậm
      },
      {
        'name': 'Hóa đơn',
        'description': 'Internet, sửa chữa...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'bill',
        'color_hex': '#26C6DA', // Xanh ngọc đậm
      },
      {
        'name': 'Sức khỏe',
        'description': 'Thuốc men, khám bệnh...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'health',
        'color_hex': '#FF7043', // Cam đỏ đậm
      },

      // --- CHI TIÊU (Expense) - NHÓM CÁ NHÂN ---
      {
        'name': 'Cà phê',
        'description': 'Trà, cafe, sinh tố...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'coffee',
        'color_hex': '#8D6E63', // Nâu đậm
      },
      {
        'name': 'Mua sắm',
        'description': 'Quần áo, giày dép...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'shopping',
        'color_hex': '#7E57C2', // Tím đậm
      },
      {
        'name': 'Giải trí',
        'description': 'Xem phim, game...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'game',
        'color_hex': '#EC407A', // Hồng tím đậm
      },
      {
        'name': 'Du lịch',
        'description': 'Vé máy bay, khách sạn...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'travel',
        'color_hex': '#FBC02D', // Vàng đậm (Thay vì vàng nhạt)
      },
      {
        'name': 'Phát triển',
        'description': 'Khóa học, sách...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'education',
        'color_hex': '#AB47BC', // Tím hồng đậm
      },
      {
        'name': 'Bạn bè',
        'description': 'Gặp gỡ, ăn uống...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'friends',
        'color_hex': '#29B6F6', // Xanh biển đậm
      },
      {
        'name': 'Sách vở',
        'description': 'Sách, văn phòng phẩm...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'book',
        'color_hex': '#EF5350', // Đỏ nhạt đậm
      },
      {
        'name': 'Dự tiệc',
        'description': 'Cưới hỏi, sinh nhật...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'party',
        'color_hex': '#66BB6A', // Xanh lá đậm
      },

      // --- CHI TIÊU (Expense) - NHÓM TÀI CHÍNH ---
      {
        'name': 'Tiết kiệm',
        'description': 'Gửi ngân hàng...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'savings',
        'color_hex': '#D81B60', // Hồng mận đậm
      },
      {
        'name': 'Đầu tư',
        'description': 'Chứng khoán, đất đai...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'invest',
        'color_hex': '#C62828', // Đỏ đậm
      },
      {
        'name': 'Trả nợ',
        'description': 'Trả tiền nợ...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'pay_debt',
        'color_hex': '#5C6BC0', // Xanh chàm đậm
      },
      {
        'name': 'Cho vay',
        'description': 'Cho người khác vay...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'loan',
        'color_hex': '#009688', // Xanh Teal đậm
      },
      {
        'name': 'Gia đình',
        'description': 'Biếu bố mẹ...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'family',
        'color_hex': '#FFCA28', // Vàng cam đậm
      },
      {
        'name': 'Từ thiện',
        'description': 'Quyên góp...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'charity',
        'color_hex': '#42A5F5', // Xanh dương
      },

      // --- THU NHẬP (Income) ---
      {
        'name': 'Lương',
        'description': 'Lương cứng...',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'salary',
        'color_hex': '#43A047', // Xanh lá cây đậm
      },
      {
        'name': 'Làm thêm',
        'description': 'Freelance, ngoài giờ...',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'part_time',
        'color_hex': '#8BC34A', // Xanh nõn chuối đậm
      },
      {
        'name': 'Được trả nợ',
        'description': 'Thu hồi nợ...',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'debt_collection',
        'color_hex': '#00ACC1', // Xanh Cyan đậm
      },
      {
        'name': 'Khác',
        'description': 'Nguồn thu khác...',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'other_income',
        'color_hex': '#FFA000', // Vàng cam đậm
      },
    ];

    for (var cat in categories) {
      await db.insert('categories', cat);
    }
  }

  // --- CÁC HÀM ĐỂ GỌI KHI LÀM GIAO DIỆN (API LOCAL) ---

  // 1. Thêm giao dịch mới
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  // 2. Lấy tất cả giao dịch (kèm thông tin danh mục)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    // Dùng lệnh SQL để nối bảng Giao dịch và Danh mục
    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon_key, c.color_hex, c.type
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC
''');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // 3. Xoá giao dịch dựa trên ID
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // 4. Cập nhật giao dịch
 Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return db.update(
      'transactions', // Tên bảng
      transaction.toMap(),
      where: 'id = ?', // Điều kiện tìm kiếm theo ID
      whereArgs: [transaction.id], // Truyền ID vào
    );
  }

  // 5. Lấy giao dịch trong một tháng cụ thể (Ví dụ: Tháng 10/2023)
 Future<List<TransactionModel>> getTransactionsByMonth(
    int month,
    int year,
    String userId,
  ) async {
    final db = await instance.database;

    // Ngày đầu tháng: 2026-01-01 00:00:00
    String startDate = DateTime(year, month, 1).toIso8601String();
    
    // --- SỬA ĐOẠN NÀY ---
    // Lấy ngày cuối tháng: Tạo ngày 0 của tháng sau = ngày cuối tháng này
    DateTime lastDay = DateTime(year, month + 1, 0);
    // Ép giờ về giây cuối cùng: 2026-01-31 23:59:59
    String endDate = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59).toIso8601String();
    // --------------------

    final result = await db.rawQuery(
      '''
        SELECT t.*, c.name as category_name, c.icon_key, c.color_hex, c.type
        FROM transactions t
        INNER JOIN categories c ON t.category_id = c.id
        WHERE t.user_id = ? AND t.date >= ? AND t.date <= ?
        ORDER BY t.date DESC
      ''',
      [userId, startDate, endDate],
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // 6. Lấy giao dịch trong khoảng thời gian bất kỳ (Lọc cho Ngày/Tuần/Năm)
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;

    // Đảm bảo lấy từ đầu ngày start đến cuối ngày end
    String startDateStr = start.toIso8601String();
    String endDateStr = end.toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT t.*, c.name as category_name, c.icon_key, c.color_hex, c.type
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC
      ''',
      [startDateStr, endDateStr],
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // 7. Tính tổng tiền Thu hoặc Chi trong khoảng thời gian (Dùng trong Dashboard)
  Future<double> calculateTotal(
    String type,
    DateTime start,
    DateTime end,
    String userId,
  ) async {
    final db = await instance.database;

    String startDateStr = start.toIso8601String();
    String endDateStr = end.toIso8601String();

    // SQL: Tính tổng cột amount WHERE type = 'expense' AND date trong khoảng ...
    final result = await db.rawQuery(
      '''
      SELECT SUM(t.amount) as total
      FROM transactions t 
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND c.type = ? AND t.date >= ? AND t.date <= ?
''',
      [userId,type, startDateStr, endDateStr],
    );

    if (result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // 8. Lấy dữ liệu thống kê theo danh mục ( Dùng cho biểu đồ tròn)
  Future<List<Map<String, dynamic>>> getCategoryStats(
    String type,
    DateTime start,
    DateTime end,
    String userId,
  ) async {
    final db = await instance.database;

    String startDateStr = start.toIso8601String();
    String endDateStr = end.toIso8601String();

    return await db.rawQuery(
      '''
      SELECT c.name, c.color_hex, SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND c.type = ? AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
''',
      [userId, type, startDateStr, endDateStr],
    );
  }

  // 9. Lấy danh sách danh mục theo loại (income/expense)
  // Dùng để hiển thị lên màn hình "Thêm giao dịch"
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
    );
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  // 10. Lấy tất cả danh mục ( Dùng cho màn hình Quản lý danh mục)
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  // 11. Thêm danh mục mới (Cho phép người dùng tạo)
  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  // 12. Xoá danh mục
  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    // Lưu ý: Cần phải xử lý logic nếu xoá danh mục đã có giao dịch (có thể chặn hoặc chuyển giao dịch sang 'Khác')
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // 12a. Cập nhật danh mục
  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 13. Lấy danh sách ghi chú duy nhất đã từng nhập cho một danh mục cụ thể
Future<List<String>> getUniqueNotesByCategory(int categoryId) async {
  final db = await instance.database;
  final result = await db.rawQuery('''
    SELECT DISTINCT note FROM transactions 
    WHERE category_id = ? AND note != '' 
    ORDER BY id DESC LIMIT 5
  ''', [categoryId]);
  
  return result.map((row) => row['note'] as String).toList();
}
  // 14. Lấy thông tin danh mục theo ID
Future<CategoryModel?> getCategoryById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return CategoryModel.fromMap(result.first);
    } else {
      return null;
    }
  }

// 15. Lấy dữ liệu chi tiêu theo ngày để vẽ biểu đồ đường
Future<List<Map<String, dynamic>>> getDailyExpenseStats(DateTime start, DateTime end, String userId) async {
    final db = await instance.database;

    // QUAN TRỌNG: Database của bạn lưu ngày dạng TEXT (ISO8601), 
    // nên phải convert sang String để so sánh, không dùng millisecondsSinceEpoch.
    String startDateStr = start.toIso8601String();
    String endDateStr = end.toIso8601String();

    // Sử dụng rawQuery để JOIN bảng transactions và categories
    // Logic: Lấy giao dịch (t) có danh mục (c) mà loại của danh mục đó là 'expense'
    final result = await db.rawQuery('''
      SELECT t.date, t.amount
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE c.type = ? AND t.user_id = ? AND t.date >= ? AND t.date <= ?
      ORDER BY t.date ASC
    ''', ['expense', userId, startDateStr, endDateStr]);

    return result;
  }
}
