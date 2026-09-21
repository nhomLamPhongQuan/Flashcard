import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../services/vocab_repository.dart';

/// Trạng thái dùng chung cho toàn app (bản giao diện: chưa có SRS/lưu trữ,
/// tiến độ "đã thuộc" chỉ giữ trong bộ nhớ của phiên hiện tại).
class AppState extends ChangeNotifier {
  AppState(this._repo);

  final VocabRepository _repo;

  List<Deck> _decks = const [];
  final Set<String> _learned = {};
  Lang _lang = Lang.en;
  ThemeMode _themeMode = ThemeMode.system;

  List<Deck> get decks => _decks;
  Lang get lang => _lang;
  ThemeMode get themeMode => _themeMode;

  List<Deck> get decksOfLang =>
      _decks.where((d) => d.lang == _lang).toList(growable: false);

  List<Word> get wordsOfLang =>
      decksOfLang.expand((d) => d.words).toList(growable: false);

  Future<void> init() async {
    _decks = await _repo.load();
  }

  void setLang(Lang lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool isLearned(Word w) => _learned.contains(w.id);

  void markLearned(Word w, {required bool learned}) {
    if (learned) {
      _learned.add(w.id);
    } else {
      _learned.remove(w.id);
    }
    notifyListeners();
  }

  int learnedCountOf(Iterable<Word> words) =>
      words.where((w) => _learned.contains(w.id)).length;
}

/// Cung cấp AppState cho toàn bộ cây widget (đặt phía trên MaterialApp).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trong cây widget');
    return scope!.notifier!;
  }
}
