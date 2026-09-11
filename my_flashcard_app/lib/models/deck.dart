class Deck {
  final String id; // Mã định danh duy nhất của Bộ thẻ (Primary Key)
  final String title; // Tiêu đề/Tên của Bộ thẻ
  final String? description; // Mô tả ngắn gọn về bộ thẻ (tùy chọn)
  final String
      colorCategory; // Thẻ màu để trang trí giao diện UI (mặc định: 'blue')
  final DateTime createdAt; // Ngày tạo bộ thẻ

  Deck({
    required this.id,
    required this.title,
    this.description,
    this.colorCategory = 'blue',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Đóng gói đối tượng Deck thành Map để ghi vào bảng 'decks' trong SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'colorCategory': colorCategory,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Giải mã dữ liệu Map đọc từ SQLite thành đối tượng Deck
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      colorCategory: map['colorCategory'] ?? 'blue',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
