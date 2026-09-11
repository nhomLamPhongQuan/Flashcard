class Flashcard {
  // Các thuộc tính bất biến (không thể sửa đổi sau khi khởi tạo)
  final String id; // Mã định danh duy nhất của thẻ (Primary Key)
  final String deckId; // Mã định danh của Bộ thẻ chứa thẻ này (Foreign Key)
  final String question; // Nội dung câu hỏi / từ vựng (Mặt trước)
  final String answer; // Nội dung đáp án / định nghĩa (Mặt sau)
  final String?
      hint; // Gợi ý cho câu hỏi (Nullable: có thể null nếu không điền)

  // Thuộc tính có thể biến đổi theo thời gian
  bool isLearned; // Trạng thái đã thuộc (true) hay chưa thuộc (false)

  final DateTime createdAt; // Mốc thời gian tạo thẻ

  // Constructor sử dụng Named Parameters (tham số có tên)
  Flashcard({
    required this.id, // Bắt buộc phải truyền ID
    required this.deckId, // Bắt buộc phải truyền ID của Bộ thẻ
    required this.question, // Bắt buộc phải truyền câu hỏi
    required this.answer, // Bắt buộc phải truyền đáp án
    this.hint, // Tham số tùy chọn (có thể bỏ trống)
    this.isLearned =
        false, // Giá trị mặc định khi mới tạo là chưa thuộc (false)
    DateTime? createdAt, // Nhận vào mốc thời gian tùy chọn
  }) : createdAt = createdAt ??
            DateTime
                .now(); // Nếu không truyền thời gian, lấy thời điểm hiện tại

  // Phương thức hỗ trợ đổi trạng thái học nhanh
  void toggleLearned() {
    isLearned = !isLearned; // Đảo giá trị: true -> false hoặc false -> true
  }

  // Chuyển đối tượng Flashcard thành Map để chuẩn bị lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'hint': hint,
      'isLearned':
          isLearned, // Lưu ý: khi lưu xuống SQLite sẽ đổi bool thành 0/1 ở tầng DB
      'createdAt': createdAt
          .toIso8601String(), // Đổi DateTime thành dạng chuỗi văn bản chuẩn ISO
    };
  }

  // Factory Constructor: Tạo đối tượng Flashcard từ dữ liệu Map (khi đọc từ SQLite ra)
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'], // Rút giá trị cột 'id'
      deckId: map['deckId'], // Rút giá trị cột 'deckId'
      question: map['question'], // Rút giá trị cột 'question'
      answer: map['answer'], // Rút giá trị cột 'answer'
      hint: map['hint'], // Rút giá trị cột 'hint'
      isLearned:
          map['isLearned'] ?? false, // Rút trạng thái, mặc định false nếu null
      createdAt: DateTime.parse(
          map['createdAt']), // Chuyển chuỗi ISO ngược lại thành DateTime
    );
  }
}
