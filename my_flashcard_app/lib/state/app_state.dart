import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/srs.dart';
import '../models/vocab.dart';
import '../services/auth_service.dart';
import '../services/cloud_progress_service.dart';
import '../services/vocab_repository.dart';

/// Trạng thái dùng chung cho toàn app.
///
/// Tiến độ học (hộp Leitner + ngày ôn tiếp theo của từng từ) luôn được lưu
/// local qua `shared_preferences` trước (offline-first, không cần mạng).
/// Khi có tài khoản đăng nhập (kể cả ẩn danh), tiến độ còn được đồng bộ lên
/// Cloud Firestore theo uid, để đổi máy/đăng nhập lại vẫn thấy tiến độ cũ.
class AppState extends ChangeNotifier {
  AppState(
    this._repo, {
    AuthService? auth,
    CloudProgressService? cloud,
  })  : auth = auth ?? AuthService(),
        _cloud = cloud ?? CloudProgressService();

  static const _progressKey = 'srs_progress_v1';
  static const _themeKey = 'theme_mode_v1';
  static const _langKey = 'lang_v1';

  final VocabRepository _repo;

  /// Public để UI (LoginPage, StatsTab...) gọi thẳng các hàm đăng nhập/đăng xuất.
  final AuthService auth;
  final CloudProgressService _cloud;

  SharedPreferences? _prefs;
  StreamSubscription<String?>? _authSub;
  String? _uid;

  List<Deck> _decks = const [];
  final Map<String, WordProgress> _progress = {};
  Lang _lang = Lang.en;
  ThemeMode _themeMode = ThemeMode.system;
  bool _ready = false;
  bool _syncing = false;

  List<Deck> get decks => _decks;
  Lang get lang => _lang;
  ThemeMode get themeMode => _themeMode;

  /// true khi đã đọc xong kho từ + tiến độ local, sẵn sàng hiển thị.
  bool get ready => _ready;

  /// true trong lúc đang merge/đẩy tiến độ lên Firestore sau khi đăng nhập.
  bool get syncing => _syncing;

  List<Deck> get decksOfLang =>
      _decks.where((d) => d.lang == _lang).toList(growable: false);

  List<Word> get wordsOfLang =>
      decksOfLang.expand((d) => d.words).toList(growable: false);

  Future<void> init() async {
    _decks = await _repo.load();
    _prefs = await SharedPreferences.getInstance();
    _restoreLocal();
    _ready = true;
    notifyListeners();

    // Lắng nghe suốt vòng đời app: mỗi lần đăng nhập/đăng xuất/đổi tài
    // khoản, merge tiến độ local hiện có với tiến độ đã lưu trên Firestore.
    _authSub = auth.uidChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(String? uid) async {
    if (uid == _uid) return;
    _uid = uid;
    if (uid == null) return; // đăng xuất: vẫn giữ tiến độ local trên máy
    await _syncWithCloud(uid);
  }

  Future<void> _syncWithCloud(String uid) async {
    _syncing = true;
    notifyListeners();
    try {
      final cloud = await _cloud.fetch(uid);
      final merged = <String, WordProgress>{...cloud};
      for (final entry in _progress.entries) {
        final existing = merged[entry.key];
        if (existing == null || _isFurtherAlong(entry.value, existing)) {
          merged[entry.key] = entry.value;
        }
      }
      _progress
        ..clear()
        ..addAll(merged);
      notifyListeners();
      await _persistLocal();
      await _cloud.push(uid, _progress);
    } catch (_) {
      // Không có mạng hoặc Firestore lỗi: cứ tiếp tục với dữ liệu local,
      // lần đăng nhập/mở app sau sẽ thử đồng bộ lại.
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// So sánh 2 tiến độ của cùng 1 từ khi merge: ưu tiên hộp cao hơn (học
  /// chắc hơn); nếu bằng hộp thì ưu tiên lần ôn gần đây hơn.
  bool _isFurtherAlong(WordProgress a, WordProgress b) {
    if (a.box != b.box) return a.box > b.box;
    return a.nextReview.isAfter(b.nextReview);
  }

  void _restoreLocal() {
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

  Future<void> _persistLocal() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final map = _progress.map((id, p) => MapEntry(id, p.toJson()));
    await prefs.setString(_progressKey, jsonEncode(map));
  }

  /// Đẩy tiến độ hiện tại lên Firestore nếu đang đăng nhập. Cố tình không
  /// `await` ở nơi gọi để không làm khựng UI khi lật thẻ liên tục; lỗi
  /// mạng ở đây không nên chặn việc học tiếp.
  void _pushIfSignedIn() {
    final uid = _uid;
    if (uid == null) return;
    _cloud.push(uid, _progress).catchError((_) {});
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
    _persistLocal();
    _pushIfSignedIn();
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
    _persistLocal();
    _pushIfSignedIn();
  }

  /// Xoá sạch tiến độ local (dùng khi đăng xuất hẳn và muốn học từ đầu
  /// trên máy này). Không đụng tới dữ liệu đã lưu trên Firestore.
  Future<void> clearLocalProgress() async {
    _progress.clear();
    notifyListeners();
    await _persistLocal();
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
