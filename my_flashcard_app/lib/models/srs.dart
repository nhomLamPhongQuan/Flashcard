/// Hệ thống ôn tập ngắt quãng kiểu hộp Leitner.
///
/// 6 hộp (0 → 5). Hộp càng cao thì bạn nhớ từ đó càng chắc, và khoảng cách
/// tới lần ôn tiếp theo càng dài. Hộp >= [kMasteredBox] coi là "đã thành thạo".
library;

/// Số ngày chờ tới lần ôn tiếp theo, ứng với chỉ số hộp (index = số hộp).
const List<int> kBoxIntervalsDays = [0, 1, 3, 7, 14, 30];

/// Từ ở hộp này trở lên được coi là đã thành thạo.
const int kMasteredBox = 3;

/// Hộp cao nhất có thể đạt được.
const int kMaxBox = 5;

/// 4 mức tự đánh giá sau khi lật thẻ, giống Anki/Leitner cổ điển.
enum SrsRating { again, hard, good, easy }

extension SrsRatingInfo on SrsRating {
  String get label {
    switch (this) {
      case SrsRating.again:
        return 'Học lại';
      case SrsRating.hard:
        return 'Khó';
      case SrsRating.good:
        return 'Nhớ';
      case SrsRating.easy:
        return 'Dễ';
    }
  }
}

/// Tiến độ ôn tập của một từ: đang ở hộp nào, lần ôn tiếp theo là khi nào.
class WordProgress {
  const WordProgress({required this.box, required this.nextReview});

  final int box;
  final DateTime nextReview;

  /// Từ chưa từng được học: hộp 0, "đến hạn" ngay lập tức.
  factory WordProgress.initial() => WordProgress(
        box: 0,
        nextReview: DateTime.fromMillisecondsSinceEpoch(0),
      );

  bool get isMastered => box >= kMasteredBox;

  bool isDue(DateTime now) => !nextReview.isAfter(now);

  /// Hộp mới sau khi người học tự đánh giá.
  int nextBoxFor(SrsRating rating) {
    switch (rating) {
      case SrsRating.again:
        return 0;
      case SrsRating.hard:
        return box > 0 ? box - 1 : 0;
      case SrsRating.good:
        return box + 1 > kMaxBox ? kMaxBox : box + 1;
      case SrsRating.easy:
        return box + 2 > kMaxBox ? kMaxBox : box + 2;
    }
  }

  /// Tạo tiến độ mới sau khi đánh giá [rating] tại thời điểm [now].
  WordProgress rated(SrsRating rating, DateTime now) {
    final newBox = nextBoxFor(rating);
    return WordProgress(
      box: newBox,
      nextReview: now.add(Duration(days: kBoxIntervalsDays[newBox])),
    );
  }

  Map<String, dynamic> toJson() => {
        'box': box,
        'next': nextReview.millisecondsSinceEpoch,
      };

  factory WordProgress.fromJson(Map<String, dynamic> json) => WordProgress(
        box: (json['box'] as num).toInt(),
        nextReview: DateTime.fromMillisecondsSinceEpoch((json['next'] as num).toInt()),
      );
}
