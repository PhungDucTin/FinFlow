class CategoryModel {
  final int? id; //Mã định danh (Tự động tăng)
  final String name; //Tên: Ăn uống, Lương,..
  final String? description; //Mô tả danh mục
  final String type; //Loại: Thu nhập hoặc Chi tiêu ( 'income' | 'expense' )
  final String groupName; //Nhóm danh mục: Mặc định hoặc Tùy chỉnh
  final String iconKey;
  final String colorHex;

  // Hàm khởi tạo (Constructor)
  CategoryModel({
    this.id,
    required this.name,
    this.description,
    required this.type,
    required this.groupName,
    required this.iconKey,
    required this.colorHex,
  });

  // Hàm 1: Biến đổi dữ liệu từ Database (dạng Map) sang thành Object để dùng trong Code
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      groupName: map['group_name'],
      iconKey: map['icon_key'],
      colorHex: map['color_hex'],
    );
  }

  // Hàm 2: Biến đổi Object thành Map để lưu vào Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'group_name': groupName,
      'icon_key': iconKey,
      'color_hex': colorHex,
    };
  }
}
