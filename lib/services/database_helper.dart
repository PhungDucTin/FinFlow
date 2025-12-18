import 'package:flutter/rendering.dart';
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
        'description': 'Ăn sáng 🍞, Ăn trưa 🥗, Ăn tối 🍟, Đi chợ 🛒...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'food',
        'color_hex': '#FFE0B2',
      },
      {
        'name': 'Đi lại',
        'description': 'Xăng xe 🚗, Xe bus 🚌, Taxi 🚕, Grab 🚘...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'transport',
        'color_hex': '#F8BBD0',
      },
      {
        'name': 'Nhà cửa',
        'description': 'Thuê nhà 🏠, Điện 💡, Nước 🚿, Internet 📶...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'house',
        'color_hex': '#BBDEFB',
      },
      {
        'name': 'Hóa đơn',
        'description': 'Hóa đơn 🧾, Sửa chữa nhà 🛠, Sửa chữa xe 🚗...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'bill',
        'color_hex': '#B2DFDB',
      },
      {
        'name': 'Sức khỏe',
        'description': 'Khám bệnh 🩺, Thuốc men 💊, Bảo hiểm 🏥...',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'health',
        'color_hex': '#FFCCBC',
      },

      // --- CHI TIÊU (Expense) - NHÓM CÁ NHÂN ---
      {
        'name': 'Cà phê',
        'description': 'Trà đá 🍵, Cà phê ☕, Sinh tố 🍹, Trà sữa 🧋...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'coffee',
        'color_hex': '#E1BEE7',
      },
      {
        'name': 'Mua sắm',
        'description': 'Quần áo 👕, Giày dép 👠, Phụ kiện 🕶...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'shopping',
        'color_hex': '#C5CAE9',
      },
      {
        'name': 'Giải trí',
        'description': 'Xem phim 🎬, Đĩa nhạc 🎧, Game 🎮...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'game',
        'color_hex': '#FFCDD2',
      },
      {
        'name': 'Du lịch',
        'description': 'Du lịch 🚗, Nghỉ dưỡng 🏖, Vé máy bay ✈...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'travel',
        'color_hex': '#FFF9C4',
      },
      {
        'name': 'Phát triển bản thân',
        'description': 'Mua khóa học 📖, Mua phần mềm 📱...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'education',
        'color_hex': '#E1BEE7',
      },
      {
        'name': 'Gặp gỡ bạn bè',
        'description': 'Ăn uống 🍽, Hát hò 🎤, Đi chơi 🎡...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'friends',
        'color_hex': '#B3E5FC',
      },
      {
        'name': 'Sách vở',
        'description': 'Sách 📚, Vở 📒, Bút 🖊, Bút chì ✏...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'book',
        'color_hex': '#FFCDD2',
      },
      {
        'name': 'Dự tiệc',
        'description': 'Tiệc cưới 💒, Tiệc sinh nhật 🎂, Tiệc lễ hội 🎉...',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'party',
        'color_hex': '#C8E6C9',
      },

      // --- CHI TIÊU (Expense) - NHÓM TÀI CHÍNH ---
      {
        'name': 'Tiết kiệm',
        'description': 'Tiền gửi ngân hàng 💰, Tiền gửi heo đất 🐷...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'savings',
        'color_hex': '#F06292',
      },
      {
        'name': 'Đầu tư',
        'description': 'Đầu tư Đất đai 🏞, Đầu tư Chứng khoán 📈...',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'invest',
        'color_hex': '#F44336',
      },
      {
        'name': 'Trả nợ',
        'description': 'Trả nợ cho người khác 💸',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'pay_debt',
        'color_hex': '#9575CD',
      },
      {
        'name': 'Cho vay',
        'description': 'Cho người khác vay tiền 🤝',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'loan',
        'color_hex': '#4DB6AC',
      },
      {
        'name': 'Hỗ trợ gia đình',
        'description': 'Hỗ trợ gia đình người thân 👨‍👩‍👧‍👦',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'family',
        'color_hex': '#FFB74D',
      },
      {
        'name': 'Ủng hộ từ thiện',
        'description': 'Tiền quyên góp cho tổ chức ❤️',
        'type': 'expense',
        'group_name': 'Tài chính',
        'icon_key': 'charity',
        'color_hex': '#64B5F6',
      },

      // --- THU NHẬP (Income) ---
      {
        'name': 'Tiền lương',
        'description': 'Lương nhận được từ công việc hàng tháng 💵',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'salary',
        'color_hex': '#C8E6C9',
      },
      {
        'name': 'Làm thêm - Ngoài giờ',
        'description': 'Lương nhận được từ làm thêm ⏰',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'part_time',
        'color_hex': '#DCEDC8',
      },
      {
        'name': 'Được trả nợ',
        'description': 'Tiền nhận được từ việc được trả nợ 🔙',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'debt_collection',
        'color_hex': '#B2DFDB',
      },
      {
        'name': 'Thu nhập khác',
        'description': 'Thu nhập từ các nguồn khác 🎁',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'other_income',
        'color_hex': '#FFE0B2',
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
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // 5. Lấy giao dịch trong một tháng cụ thể (Ví dụ: Tháng 10/2023)
  Future<List<TransactionModel>> getTransactionsByMonth(
    int month,
    int year,
  ) async {
    final db = await instance.database;

    // Tạo chuỗi ngày đầu tháng và cuối tháng để lọc
    String startDate = DateTime(year, month, 1).toIso8601String();
    // Lấy ngày đầu của tháng sau trừ đi 1 để ra ngày cuối của tháng này
    String endDate = DateTime(year, month + 1, 0).toIso8601String();

    final result = await db.rawQuery(
      '''
        SELECT t.*, c.name as category_name, c.icon_key, c.color_hex, c.type
        FROM transactions t
        INNER JOIN categories c ON t.category_id = c.id
        WHERE t.date >= ? AND t.date <= ?
        ORDER BY t.date DESC
      ''',
      [startDate, endDate],
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
      WHERE c.type = ? AND t.date >= ? AND t.date <= ?
''',
      [type, startDateStr, endDateStr],
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
  ) async {
    final db = await instance.database;

    String startDateStr = start.toIso8601String();
    String endDateStr = end.toIso8601String();

    return await db.rawQuery(
      '''
      SELECT c.name, c.color_hex, SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE c.type = ? AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
''',
      [type, startDateStr, endDateStr],
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
}
