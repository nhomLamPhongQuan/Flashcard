class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String? hint; // Dấu ? cho phép hint có thể null (không bắt buộc)
  bool isLearned;
  final DateTime createdAt;

  // Constructor sử dụng named parameters
  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.hint,
    this.isLearned = false, // Mặc định thẻ mới chưa học
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Phương thức đảo trạng thái học của thẻ
  void toggleLearned() {
    isLearned = !isLearned;
  }

  // Chuyển đối tượng Flashcard thành Map (để chuẩn bị cho việc lưu vào bộ nhớ / JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'hint': hint,
      'isLearned': isLearned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Khởi tạo một Flashcard từ dữ liệu Map (để đọc từ bộ nhớ / JSON ra)
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      hint: map['hint'],
      isLearned: map['isLearned'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
