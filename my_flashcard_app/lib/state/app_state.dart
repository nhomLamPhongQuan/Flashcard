import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/srs.dart';
import '../models/vocab.dart';
import '../services/vocab_repository.dart';

/// Trạng thái dùng chung cho toàn app.
///
/// Tiến độ học (hộp Leitner + ngày ôn tiếp theo của từng từ) được lưu vĩnh
/// viễn bằng `shared_preferences`, dưới dạng 1 chuỗi JSON duy nhất
/// (id từ -> {box, next}), nên tắt/mở lại app không bị mất.
class AppState extends ChangeNotifier {
  AppState(this._repo);

  static const _progressKey = 'srs_progress_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _langKey = 'lang_v1';

  final VocabRepository _repo;
  SharedPreferences? _prefs;

  List<Deck> _decks = const [];
  final Map<String, WordProgress> _progress = {};
  Lang _lang = Lang.en;
  ThemeMode _themeMode = ThemeMode.system;
  bool _ready = false;

  List<Deck> get decks => _decks;
  Lang get lang => _lang;
  ThemeMode get themeMode => _themeMode;

  /// true khi đã đọc xong kho từ + tiến độ đã lưu, sẵn sàng hiển thị.
  bool get ready => _ready;

  List<Deck> get decksOfLang =>
      _decks.where((d) => d.lang == _lang).toList(growable: false);

  List<Word> get wordsOfLang =>
      decksOfLang.expand((d) => d.words).toList(growable: false);

  Future<void> init() async {
    _decks = await _repo.load();
    _prefs = await SharedPreferences.getInstance();
    _restore();
    _ready = true;
    notifyListeners();
  }

  void _restore() {
    final prefs = _prefs;
    if (prefs == null) return;

    final rawProgress = prefs.getString(_progressKey);
    if (rawProgress != null && rawProgress.isNotEmpty) {
      final map = jsonDecode(rawProgress) as Map<String, dynamic>;
      map.forEach((id, value) {
        _progress[id] = WordProgress.fromJson(value as Map<String, dynamic>);
      });
    }

    final savedLang = prefs.getString(_langKey);
    if (savedLang != null) _lang = langFromCode(savedLang);

    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> _persistProgress() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final map = _progress.map((id, p) => MapEntry(id, p.toJson()));
    await prefs.setString(_progressKey, jsonEncode(map));
  }

  void setLang(Lang lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
    _prefs?.setString(_langKey, lang.code);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _prefs?.setString(_themeKey, mode.name);
  }

  // ---- SRS (hộp Leitner) ----

  WordProgress progressOf(Word w) => _progress[w.id] ?? WordProgress.initial();

  bool isMastered(Word w) => progressOf(w).isMastered;

  bool isDue(Word w, {DateTime? now}) =>
      progressOf(w).isDue(now ?? DateTime.now());

  List<Word> dueWords(Iterable<Word> words, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return words.where((w) => progressOf(w).isDue(n)).toList();
  }

  int masteredCountOf(Iterable<Word> words) => words.where(isMastered).length;

  int dueCountOf(Iterable<Word> words, {DateTime? now}) =>
      dueWords(words, now: now).length;

  /// Ghi nhận người học tự đánh giá 1 từ sau khi lật thẻ (luồng học chính).
  void rate(Word w, SrsRating rating) {
    final current = progressOf(w);
    _progress[w.id] = current.rated(rating, DateTime.now());
    notifyListeners();
    _persistProgress();
  }

  /// Đánh dấu/gỡ đánh dấu "đã thành thạo" thủ công (vd. từ trang Kho từ),
  /// không qua luồng lật thẻ.
  void markMastered(Word w, {required bool mastered}) {
    if (mastered) {
      _progress[w.id] = WordProgress(
        box: kMasteredBox,
        nextReview:
            DateTime.now().add(Duration(days: kBoxIntervalsDays[kMasteredBox])),
      );
    } else {
      _progress.remove(w.id);
    }
    notifyListeners();
    _persistProgress();
  }
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
