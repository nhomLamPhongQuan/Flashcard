import '../models/deck.dart';
import '../models/flashcard.dart';

class MockData {
  static final List<Deck> defaultDecks = [
    Deck(
      id: 'deck_ielts',
      title: 'IELTS Academic Vocabulary',
      description: 'Từ vựng ăn điểm cho kỹ năng Reading & Writing',
      colorCategory: 'indigo',
    ),
    Deck(
      id: 'deck_toeic',
      title: 'TOEIC Business English',
      description: 'Từ vựng giao tiếp thương mại, văn phòng',
      colorCategory: 'teal',
    ),
    Deck(
      id: 'deck_n3',
      title: 'Từ vựng tiếng Nhật JLPT N3',
      description: 'Tổng hợp từ vựng N3 trung cấp thường gặp',
      colorCategory: 'orange',
    ),
  ];

  static final List<Flashcard> defaultCards = [
    Flashcard(
      id: 'ielts_1',
      deckId: 'deck_ielts',
      question: 'Meticulous (adj)',
      answer: 'Tỉ mỉ, kỹ lưỡng, cẩn thận từng chi tiết nhỏ',
      hint: 'Very careful and precise',
    ),
    Flashcard(
      id: 'ielts_2',
      deckId: 'deck_ielts',
      question: 'Abundant (adj)',
      answer: 'Dồi dào, phong phú, nhiều',
      hint: 'Existing or available in large quantities',
    ),
    Flashcard(
      id: 'toeic_1',
      deckId: 'deck_toeic',
      question: 'Negotiate (v)',
      answer: 'Đàm phán, thương lượng hợp đồng',
      hint: 'Try to reach an agreement by discussion',
    ),
    Flashcard(
      id: 'n3_1',
      deckId: 'deck_n3',
      question: '遠慮 (えんりょ)',
      answer: 'Ngần ngại, khách khí, e ngại',
      hint: 'Dùng khi từ chối lịch sự trong giao tiếp',
    ),
  ];
}
