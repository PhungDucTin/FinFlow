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
      //Chi tiêu - Thiết yếu
      {
        'name': 'Ăn uống',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'food',
        'color_hex': '#FFE0B2',
      },
      {
        'name': 'Đi lại',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'transport',
        'color_hex': '#F8BBD0',
      },
      {
        'name': 'Hóa đơn',
        'type': 'expense',
        'group_name': 'Thiết yếu',
        'icon_key': 'bill',
        'color_hex': '#B2DFDB',
      },

      // Chi tiêu - Cá nhân
      {
        'name': 'Mua sắm',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'shopping',
        'color_hex': '#C5CAE9',
      },
      {
        'name': 'Giải trí',
        'type': 'expense',
        'group_name': 'Cá nhân',
        'icon_key': 'game',
        'color_hex': '#FFCDD2',
      },

      // Thu nhập
      {
        'name': 'Lương',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'salary',
        'color_hex': '#C8E6C9',
      },
      {
        'name': 'Thưởng',
        'type': 'income',
        'group_name': 'Thu nhập',
        'icon_key': 'bonus',
        'color_hex': '#C8E6C9',
      },
    ];

    // Chạy vòng lặp để thêm từng cái vào DB
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
      INNEER JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC
''');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }
}
