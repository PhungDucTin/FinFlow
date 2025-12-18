class TransactionModel {
  final int? id;
  final String? userId;
  final double amount; // Số tiền
  final String note; //Ghi chú
  final DateTime date; //Ngày giao dịch
  final int categoryId; //Mã danh mục (Khóa ngoại liên kết với CategoryModel)

  // Các biến này hứng dữ liệu khi "Nối bảng" (Join), không lưu trực tiếp
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? type;

  TransactionModel({
    this.id,
    this.userId,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.type,
  });

  //Chuyển từ Database ra Code
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount'],
      note: map['note'],
      // SQLite lưu ngày dưới dạng chữ (String), cần chuyển lại thành DateTime
      date: DateTime.parse(map['date']),
      categoryId: map['category_id'],
      // Lấy thêm thông tin danh mục nếu có
      categoryName: map['category_name'],
      categoryIcon: map['icon_key'],
      categoryColor: map['color_hex'],
      type: map['type'],
    );
  }

  //Chuyển từ Code vào Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'note': note,
      // Chuyển DateTime thành String để lưu vào SQLite
      'date': date.toIso8601String(),
      'category_id': categoryId,
    };
  }
}
