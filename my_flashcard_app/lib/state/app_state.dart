import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/srs.dart';
import '../models/vocab.dart';
import '../models/avatar_catalog.dart';
import '../models/public_stats.dart';
import '../services/auth_service.dart';
import '../services/cloud_progress_service.dart';
import '../services/display_name_service.dart';
import '../services/public_stats_service.dart';
import '../services/vocab_repository.dart';

/// Trạng thái dùng chung cho toàn app.
///
/// Tiến độ học (hộp Leitner + ngày ôn tiếp theo của từng từ) luôn được lưu
/// local qua `shared_preferences` trước (offline-first, không cần mạng).
/// Chế độ khách chỉ lưu tiến độ trên thiết bị. Tài khoản email mới đồng bộ
/// tiến độ lên Cloud Firestore theo uid.
class AppState extends ChangeNotifier {
  AppState(
    this._repo, {
    AuthService? auth,
    CloudProgressService? cloud,
    PublicStatsService? publicStats,
  })  : auth = auth ?? AuthService(),
        _cloud = cloud ?? CloudProgressService(),
        _publicStats = publicStats ?? PublicStatsService();

  static const _progressKey = 'srs_progress_v1';
  static const _guestProgressKey = 'srs_guest_progress_v1';
  static const _linkedProgressKeyPrefix = 'srs_linked_progress_v1_';
  static const _themeKey = 'theme_mode_v1';
  static const _langKey = 'lang_v1';
  static const _localGuestKey = 'local_guest_active_v1';
  static const _guestNameKey = 'local_guest_name_v1';
  static const _unlinkedUidKey = 'local_unlinked_uid_v1';
  static const _unlinkedNameKey = 'local_unlinked_name_v1';
  static const _guestAvatarKey = 'local_guest_avatar_v1';
  static const _unlinkedAvatarKey = 'local_unlinked_avatar_v1';
  static const _legacyExamStatsKey = 'exam_stats_v1';
  static const _examStatsKeyPrefix = 'exam_stats_v1_';

  final VocabRepository _repo;

  /// Public để UI (LoginPage, StatsTab...) gọi thẳng các hàm đăng nhập/đăng xuất.
  final AuthService auth;
  final CloudProgressService _cloud;
  final PublicStatsService _publicStats;

  SharedPreferences? _prefs;
  StreamSubscription<String?>? _authSub;
  String? _uid;
  String? _guestDisplayName;
  String? _unlinkedUid;
  String? _unlinkedDisplayName;
  String _avatarId = 'avatar_01';
  String _guestAvatarId = 'avatar_01';
  String? _unlinkedAvatarId;
  String? _localGuestIssue;
  Future<void> _pendingCloudPush = Future<void>.value();
  Future<void> _pendingLocalWrite = Future<void>.value();
  Future<void> _cloudSync = Future<void>.value();
  bool _cloudWritesPaused = false;
  bool _localGuest = false;
  String? _pendingLinkAvatarId;

  List<Deck> _decks = const [];
  final Map<String, WordProgress> _progress = {};
  Lang _lang = Lang.en;
  ThemeMode _themeMode = ThemeMode.system;
  bool _ready = false;
  bool _syncing = false;
  String? _displayNameIssue;
  bool _displayNameConflict = false;
  StatsPrivacySettings _statsPrivacy = const StatsPrivacySettings();
  bool _statsPrivacyReady = false;
  String? _publicStatsIssue;
  int _examCount = 0;
  int _examWordsTotal = 0;
  int _examCorrectTotal = 0;

  List<Deck> get decks => _decks;
  Lang get lang => _lang;
  ThemeMode get themeMode => _themeMode;

  /// true khi đã đọc xong kho từ + tiến độ local, sẵn sàng hiển thị.
  bool get ready => _ready;

  /// true trong lúc đang merge/đẩy tiến độ lên Firestore sau khi đăng nhập.
  bool get syncing => _syncing;
  String? get displayNameIssue => _displayNameIssue;
  bool get displayNameConflict => _displayNameConflict;
  bool get localGuest => _localGuest;
  bool get guestSession => _localGuest && _unlinkedUid == null;
  String? get localGuestIssue => _localGuestIssue;
  String? get currentDisplayName =>
      auth.currentDisplayName ??
      (_localGuest
          ? (_unlinkedUid == null ? _guestDisplayName : _unlinkedDisplayName)
          : null);
  String? get savedGuestName => _guestDisplayName;
  String get avatarId => _avatarId;
  bool get unlinkedSession => _unlinkedUid != null;
  bool get hasSavedGuest =>
      (_guestDisplayName?.isNotEmpty ?? false) ||
      (_prefs?.containsKey(_guestProgressKey) ?? false);
  int get examCount => _examCount;
  double get averageExamWords =>
      _examCount == 0 ? 0 : _examWordsTotal / _examCount;
  double get averageExamCorrect =>
      _examCount == 0 ? 0 : _examCorrectTotal / _examCount;
  StatsPrivacySettings get statsPrivacy => _statsPrivacy;
  bool get statsPrivacyReady => _statsPrivacyReady;
  String? get publicStatsIssue => _publicStatsIssue;

  List<Deck> get decksOfLang =>
      _decks.where((d) => d.lang == _lang).toList(growable: false);

  List<Word> get wordsOfLang =>
      decksOfLang.expand((d) => d.words).toList(growable: false);

  Future<void> init() async {
    _decks = await _repo.load();
    _prefs = await SharedPreferences.getInstance();
    await _restoreLocal();
    _ready = true;
    notifyListeners();

    // Chế độ khách không tạo phiên Firebase; chỉ tài khoản email được đồng bộ.
    _authSub = auth.uidChanges.listen(_onAuthChanged);
  }

  Future<void> recordExamResult({
    required int wordCount,
    required int correctCount,
  }) async {
    if (wordCount <= 0 || correctCount < 0 || correctCount > wordCount) {
      throw ArgumentError('Invalid exam result.');
    }
    final prefs = _prefs;
    if (prefs == null) throw StateError('AppState has not been initialized.');

    final uid = _uid ?? auth.currentUid;
    final isLinked = uid != null && !auth.isAnonymous && !_localGuest;
    final totals = isLinked
        ? await _publicStats.recordExamResult(
            uid: uid,
            displayName: auth.currentDisplayName ?? '',
            wordCount: wordCount,
            correctCount: correctCount,
          )
        : {
            'examCount': _examCount + 1,
            'examWordsTotal': _examWordsTotal + wordCount,
            'examCorrectTotal': _examCorrectTotal + correctCount,
          };
    final examCount = totals['examCount']!;
    final wordsTotal = totals['examWordsTotal']!;
    final correctTotal = totals['examCorrectTotal']!;
    final saved = await prefs.setString(
      _activeExamStatsKey,
      jsonEncode({
        'count': examCount,
        'words': wordsTotal,
        'correct': correctTotal,
      }),
    );
    if (!saved) throw StateError('Could not save exam statistics.');

    _examCount = examCount;
    _examWordsTotal = wordsTotal;
    _examCorrectTotal = correctTotal;
    notifyListeners();
  }

  Future<void> saveStatsPrivacy({
    required StatsPrivacyMode mode,
    required List<String> allowedViewerNames,
    required List<String> blockedViewerNames,
  }) async {
    final uid = _uid ?? auth.currentUid;
    if (uid == null || auth.isAnonymous || _localGuest) {
      throw StateError(
          'Sign in with a linked account to manage stats privacy.');
    }

    final allowedNames = mode == StatsPrivacyMode.restricted
        ? _cleanNames(allowedViewerNames)
        : <String>[];
    final blockedNames = mode == StatsPrivacyMode.open
        ? _cleanNames(blockedViewerNames)
        : <String>[];
    final allowedUids = await _resolveViewerUids(allowedNames);
    final blockedUids = await _resolveViewerUids(blockedNames);
    await _publicStats.savePrivacySettings(
      uid: uid,
      mode: mode,
      allowedViewerNames: allowedNames,
      allowedViewerUids: allowedUids,
      blockedViewerNames: blockedNames,
      blockedViewerUids: blockedUids,
    );
    _statsPrivacy = StatsPrivacySettings(
      mode: mode,
      allowedViewerNames: allowedNames,
      blockedViewerNames: blockedNames,
    );
    _publicStatsIssue = null;
    notifyListeners();
  }

  Future<PublicStats?> lookupPublicStats(String displayName) async {
    final uid = _uid ?? auth.currentUid;
    if (uid == null || auth.isAnonymous || _localGuest) {
      throw StateError('Sign in with a linked account to view stats.');
    }
    return _publicStats.findByName(displayName);
  }

  List<String> _cleanNames(List<String> names) {
    final unique = <String, String>{};
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) unique[trimmed.toLowerCase()] = trimmed;
    }
    return unique.values.toList(growable: false);
  }

  Future<List<String>> _resolveViewerUids(List<String> names) async {
    final uids = <String>[];
    for (final name in names) {
      uids.add(await DisplayNameService().uidForName(name));
    }
    return uids.toSet().toList(growable: false);
  }

  String get _activeExamStatsKey {
    final uid = _unlinkedUid ?? (_uid ?? auth.currentUid);
    return '$_examStatsKeyPrefix${uid ?? 'guest'}';
  }

  Future<void> _saveExamStatsLocally() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final saved = await prefs.setString(
      _activeExamStatsKey,
      jsonEncode({
        'count': _examCount,
        'words': _examWordsTotal,
        'correct': _examCorrectTotal,
      }),
    );
    if (!saved) throw StateError('Could not save exam statistics locally.');
  }

  Future<void> _loadExamStatsFromPrefs(String key) async {
    final prefs = _prefs;
    final raw = prefs?.getString(key);
    if (raw == null) {
      _loadExamStats(null);
      return;
    }
    _loadExamStats(jsonDecode(raw) as Map<String, dynamic>);
  }

  void _loadExamStats(Map<String, dynamic>? data) {
    _examCount = data?['count'] as int? ?? 0;
    _examWordsTotal = data?['words'] as int? ?? 0;
    _examCorrectTotal = data?['correct'] as int? ?? 0;
  }

  Map<String, dynamic> _publicStatsPayload() {
    final allWords = _decks.expand((deck) => deck.words).toList();
    return {
      'masteredCount': masteredCountOf(allWords),
      'dueCount': dueCountOf(allWords),
      'totalWords': allWords.length,
      'examCount': _examCount,
      'examWordsTotal': _examWordsTotal,
      'examCorrectTotal': _examCorrectTotal,
      'decks': _decks
          .map((deck) => {
                'title': deck.title,
                'language': deck.lang.label,
                'mastered': masteredCountOf(deck.words),
                'total': deck.words.length,
              })
          .toList(growable: false),
    };
  }

  Future<void> _publishStudyStats(String uid) async {
    final displayName = auth.currentDisplayName;
    if (displayName == null || displayName.trim().isEmpty) return;
    final stats = _publicStatsPayload();
    await _publicStats.updateStudyStats(
      uid: uid,
      displayName: displayName,
      masteredCount: stats['masteredCount'] as int,
      dueCount: stats['dueCount'] as int,
      totalWords: stats['totalWords'] as int,
      decks: List<Map<String, dynamic>>.from(stats['decks'] as List),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(String? uid) async {
    if (_unlinking && uid != null && uid == _unlinkedUid) {
      notifyListeners();
      return;
    }
    if (uid == _uid && (uid == null || auth.isAnonymous == _localGuest)) {
      notifyListeners();
      return;
    }
    final previousUid = _uid;
    final previousUnlinkedUid = _unlinkedUid;
    final wasLocalGuest = _localGuest;
    final previousUnlinkedProgress = previousUnlinkedUid == null
        ? null
        : Map<String, WordProgress>.of(_progress);
    if (previousUid != null &&
        previousUid != uid &&
        previousUid != _unlinkedUid &&
        !_unlinking) {
      _cloudWritesPaused = true;
      try {
        await _cloudSync;
        await _pendingCloudPush;
        await _pendingLocalWrite;
        await _removeLinkedProgress(previousUid);
      } finally {
        _cloudWritesPaused = false;
      }
    }
    _uid = uid;
    _displayNameIssue = null;
    _displayNameConflict = false;
    if (uid == null) {
      if (_unlinking || _unlinkedUid != null) {
        _localGuest = true;
        await _persistLocalGuest();
        notifyListeners();
        return;
      }
      if (previousUid != null) {
        _progress.clear();
        _localGuest = false;
        await _persistLocalGuest();
        await _loadExamStatsFromPrefs('$_examStatsKeyPrefix' 'guest');
      }
      notifyListeners();
      return;
    }

    if (auth.isAnonymous) {
      _localGuest = true;
      _unlinkedUid = uid;
      _unlinkedDisplayName = auth.currentDisplayName;
      _unlinkedAvatarId ??= _avatarId;
      _avatarId = _unlinkedAvatarId!;
      _loadProgress(_linkedProgressKey(uid));
      await _persistUnlinkedSession();
      _unlinking = true;
      try {
        final legacyName = await auth.removeLegacyGuestAccount();
        await _completeLegacyGuestMigration(uid, legacyName);
      } catch (error) {
        _localGuestIssue = auth.friendlyError(error);
      } finally {
        _unlinking = false;
      }
      notifyListeners();
      return;
    }

    _localGuest = false;
    _statsPrivacyReady = false;
    final carryGuestExamStats =
        previousUid == null && wasLocalGuest && previousUnlinkedUid == null;
    final previousAvatarId = _avatarId;
    _unlinkedUid = null;
    _unlinkedDisplayName = null;
    _unlinkedAvatarId = null;
    await _persistLocalGuest();
    if (!carryGuestExamStats) {
      await _loadExamStatsFromPrefs('$_examStatsKeyPrefix$uid');
    }
    _loadProgress(_linkedProgressKey(uid));
    try {
      final pendingLinkAvatarId = _pendingLinkAvatarId;
      _avatarId = pendingLinkAvatarId ??
          await _cloud.fetchAvatarId(uid) ??
          _prefs?.getString('linked_avatar_v1_$uid') ??
          (previousUnlinkedUid != null ? previousAvatarId : 'avatar_01');
      if (pendingLinkAvatarId != null) _pendingLinkAvatarId = null;
      await _prefs?.setString(
        'linked_avatar_v1_$uid',
        _avatarId,
      );
    } catch (error) {
      _avatarId = _prefs?.getString('linked_avatar_v1_$uid') ?? 'avatar_01';
      _localGuestIssue = auth.friendlyError(error);
    }
    if (previousUnlinkedProgress != null) {
      for (final entry in previousUnlinkedProgress.entries) {
        final existing = _progress[entry.key];
        if (existing == null || _isFurtherAlong(entry.value, existing)) {
          _progress[entry.key] = entry.value;
        }
      }
      await _persistLocal();
    }
    await _persistUnlinkedSession();
    if (previousUnlinkedUid != null && previousUnlinkedUid != uid) {
      await _removeLinkedProgress(previousUnlinkedUid);
    }
    try {
      await auth.ensureCurrentDisplayNameClaimed();
      _displayNameIssue = null;
    } catch (error) {
      _displayNameIssue = auth.friendlyError(error);
      _displayNameConflict = error is DisplayNameTakenException;
      notifyListeners();
    }
    if (carryGuestExamStats) await _saveExamStatsLocally();
    try {
      final displayName = auth.currentDisplayName?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        _statsPrivacy = await _publicStats.ensurePrivacySettings(uid);
        await _publicStats.ensureStatsDocument(
          uid: uid,
          displayName: displayName,
          initialStats: _publicStatsPayload(),
        );
        _statsPrivacyReady = true;
        final cloudStats = await _publicStats.fetchOwnStats(uid);
        if (cloudStats != null) {
          _examCount = cloudStats['examCount'] as int? ?? 0;
          _examWordsTotal = cloudStats['examWordsTotal'] as int? ?? 0;
          _examCorrectTotal = cloudStats['examCorrectTotal'] as int? ?? 0;
          await _saveExamStatsLocally();
        }
        _publicStatsIssue = null;
      }
    } catch (error) {
      _publicStatsIssue = auth.friendlyError(error);
    }
    _cloudSync = _syncWithCloud(uid);
    await _cloudSync;
    try {
      await _publishStudyStats(uid);
      _publicStatsIssue = null;
    } catch (error) {
      _publicStatsIssue = auth.friendlyError(error);
    }
    notifyListeners();
  }

  bool _unlinking = false;

  Future<void> startLocalGuest(
    String displayName, {
    bool replaceExisting = false,
  }) async {
    if (auth.currentUid != null) {
      throw StateError('Đăng xuất khỏi tài khoản hiện tại trước.');
    }
    if (replaceExisting) {
      _progress.clear();
      await _prefs?.remove(_guestProgressKey);
    } else {
      _loadProgress(_guestProgressKey);
    }
    _localGuest = true;
    _guestDisplayName = displayName.trim();
    _guestAvatarId = 'avatar_01';
    _avatarId = _guestAvatarId;
    _unlinkedUid = null;
    _unlinkedDisplayName = null;
    _unlinkedAvatarId = null;
    _localGuestIssue = null;
    await _persistLocalGuest();
    await _persistLocal();
    notifyListeners();
  }

  Future<void> continueLocalGuest() async {
    if (auth.currentUid != null) {
      throw StateError('Đăng xuất khỏi tài khoản hiện tại trước.');
    }
    if (!hasSavedGuest) {
      throw StateError('Không tìm thấy tài khoản khách đã lưu trên thiết bị.');
    }
    _loadProgress(_guestProgressKey);
    _guestAvatarId = _prefs?.getString(_guestAvatarKey) ?? 'avatar_01';
    _avatarId = _guestAvatarId;
    _localGuest = true;
    _unlinkedUid = null;
    _unlinkedDisplayName = null;
    _localGuestIssue = null;
    await _persistLocalGuest();
    notifyListeners();
  }

  Future<void> signOut() async {
    final uid = _uid ?? auth.currentUid;
    final unlinkedUid = _unlinkedUid;
    if (unlinkedUid == null && uid != null && !auth.isAnonymous) {
      _cloudWritesPaused = true;
    }
    try {
      if (unlinkedUid != null) {
        await _pendingLocalWrite;
        await _removeLinkedProgress(unlinkedUid);
        await _prefs?.remove('$_examStatsKeyPrefix$unlinkedUid');
        _unlinkedUid = null;
        _unlinkedDisplayName = null;
        _unlinkedAvatarId = null;
        _uid = null;
        _progress.clear();
        _loadExamStats(null);
        await _persistUnlinkedSession();
        _localGuest = false;
        _localGuestIssue = null;
        await _persistLocalGuest();
      } else if (uid != null && !auth.isAnonymous) {
        await _cloudSync;
        await _pendingCloudPush;
        await _pendingLocalWrite;
        await _removeLinkedProgress(uid);
        await _prefs?.remove('$_examStatsKeyPrefix$uid');
        _progress.clear();
        _uid = null;
        _loadExamStats(null);
      } else {
        _localGuest = false;
        _localGuestIssue = null;
        await _persistLocalGuest();
        await _loadExamStatsFromPrefs('$_examStatsKeyPrefix' 'guest');
      }
      await auth.signOut();
    } finally {
      _cloudWritesPaused = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    if (auth.currentUid != null && !auth.isAnonymous) {
      await auth.updateDisplayName(displayName);
      final uid = auth.currentUid!;
      await _publicStats.ensureStatsDocument(
        uid: uid,
        displayName: displayName.trim(),
        initialStats: _publicStatsPayload(),
      );
      await _publishStudyStats(uid);
      _publicStatsIssue = null;
      notifyListeners();
      return;
    }
    if (!_localGuest) {
      throw StateError('Chưa có phiên khách để cập nhật tên.');
    }
    if (_unlinkedUid == null) {
      _guestDisplayName = displayName.trim();
      await _persistLocalGuest();
    } else {
      _unlinkedDisplayName = displayName.trim();
      await _persistUnlinkedSession();
    }
    notifyListeners();
  }

  Future<void> selectAvatar(String avatarId) async {
    if (!avatarOptions.any((option) => option.id == avatarId)) {
      throw ArgumentError.value(avatarId, 'avatarId', 'Unknown avatar');
    }
    final uid = _uid ?? auth.currentUid;
    if (uid != null && !auth.isAnonymous && !_localGuest) {
      await _cloud.setAvatarId(uid, avatarId);
      await _prefs?.setString('linked_avatar_v1_$uid', avatarId);
    } else if (_unlinkedUid != null) {
      _unlinkedAvatarId = avatarId;
      await _prefs?.setString(_unlinkedAvatarKey, avatarId);
    } else {
      _guestAvatarId = avatarId;
      await _prefs?.setString(_guestAvatarKey, avatarId);
    }
    _avatarId = avatarId;
    notifyListeners();
  }

  Future<void> linkEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final avatarId = _avatarId;
    _pendingLinkAvatarId =
        _localGuest && _unlinkedUid == null ? avatarId : null;
    try {
      await auth.linkEmail(
        displayName: displayName,
        email: email,
        password: password,
      );
      final uid = auth.currentUid;
      if (uid != null) {
        await _cloud.setAvatarId(uid, avatarId);
        await _prefs?.setString('linked_avatar_v1_$uid', avatarId);
        _avatarId = avatarId;
      }
      notifyListeners();
    } catch (_) {
      _pendingLinkAvatarId = null;
      rethrow;
    }
  }

  Future<void> unlinkEmailAccount({
    required String confirmationName,
    required String password,
  }) async {
    final uid = auth.currentUid;
    if (uid == null || auth.isAnonymous) {
      throw StateError('Tài khoản này chưa liên kết email và mật khẩu.');
    }

    await _persistLocal();
    _cloudWritesPaused = true;
    try {
      await _cloudSync;
      await _pendingCloudPush;
    } catch (_) {
      _cloudWritesPaused = false;
      rethrow;
    }

    final previousLocalGuest = _localGuest;
    _localGuest = true;
    _unlinkedUid = uid;
    _unlinkedDisplayName = auth.currentDisplayName?.trim();
    _unlinkedAvatarId = _avatarId;
    await _prefs?.setString(_unlinkedAvatarKey, _avatarId);
    await _saveExamStatsLocally();
    _localGuestIssue = null;

    try {
      await _persistUnlinkedSession();
      notifyListeners();
      _unlinking = true;
      await auth.unlinkEmailAccount(
        confirmationName: confirmationName,
        password: password,
      );
      _uid = null;
    } catch (_) {
      _localGuest = previousLocalGuest;
      _unlinkedUid = null;
      _unlinkedDisplayName = null;
      _unlinkedAvatarId = null;
      await _prefs?.remove(_unlinkedAvatarKey);
      _uid = auth.currentUid;
      await _persistUnlinkedSession();
      _cloudWritesPaused = false;
      if (_uid != null && !auth.isAnonymous) _pushIfSignedIn();
      rethrow;
    } finally {
      _unlinking = false;
      _cloudWritesPaused = false;
      notifyListeners();
    }
  }

  Future<void> retryLegacyGuestCleanup() async {
    if (!auth.isAnonymous) return;
    final uid = auth.currentUid;
    if (uid == null) return;
    _unlinking = true;
    try {
      final legacyName = await auth.removeLegacyGuestAccount();
      await _completeLegacyGuestMigration(uid, legacyName);
    } catch (error) {
      _localGuestIssue = auth.friendlyError(error);
      rethrow;
    } finally {
      _unlinking = false;
      notifyListeners();
    }
  }

  Future<void> _completeLegacyGuestMigration(
    String uid,
    String? displayName,
  ) async {
    _guestDisplayName =
        displayName ?? _unlinkedDisplayName ?? _guestDisplayName;
    _guestAvatarId = _unlinkedAvatarId ?? _guestAvatarId;
    _avatarId = _guestAvatarId;
    await _prefs?.setString(_guestAvatarKey, _guestAvatarId);
    _localGuest = true;
    _unlinkedUid = null;
    _unlinkedDisplayName = null;
    _uid = null;
    await _persistUnlinkedSession();
    await _persistLocalGuest();
    await _persistLocal();
    await _removeLinkedProgress(uid);
    _localGuestIssue = null;
  }

  Future<void> _persistLocalGuest() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_localGuestKey, _localGuest);
    final name = _guestDisplayName;
    if (name == null || name.isEmpty) {
      await prefs.remove(_guestNameKey);
    } else {
      await prefs.setString(_guestNameKey, name);
    }
  }

  Future<void> _persistUnlinkedSession() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final uid = _unlinkedUid;
    if (uid == null) {
      await prefs.remove(_unlinkedUidKey);
      await prefs.remove(_unlinkedNameKey);
      await prefs.remove(_unlinkedAvatarKey);
      return;
    }
    await prefs.setString(_unlinkedUidKey, uid);
    final name = _unlinkedDisplayName;
    if (name == null || name.isEmpty) {
      await prefs.remove(_unlinkedNameKey);
    } else {
      await prefs.setString(_unlinkedNameKey, name);
    }
    final avatarId = _unlinkedAvatarId;
    if (avatarId == null) {
      await prefs.remove(_unlinkedAvatarKey);
    } else {
      await prefs.setString(_unlinkedAvatarKey, avatarId);
    }
  }

  String _linkedProgressKey(String uid) => '$_linkedProgressKeyPrefix$uid';

  Future<void> _removeLinkedProgress(String uid) async {
    await _prefs?.remove(_linkedProgressKey(uid));
    await _prefs?.remove('linked_avatar_v1_$uid');
  }

  void _loadProgress(String key) {
    final prefs = _prefs;
    _progress.clear();
    if (prefs == null) return;
    final rawProgress = prefs.getString(key);
    if (rawProgress == null || rawProgress.isEmpty) return;
    final map = jsonDecode(rawProgress) as Map<String, dynamic>;
    map.forEach((id, value) {
      _progress[id] = WordProgress.fromJson(value as Map<String, dynamic>);
    });
  }

  Future<void> _restoreLocal() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final savedLang = prefs.getString(_langKey);
    if (savedLang != null) _lang = langFromCode(savedLang);

    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    _localGuest = prefs.getBool(_localGuestKey) ?? false;
    _guestDisplayName = prefs.getString(_guestNameKey);
    _unlinkedUid = prefs.getString(_unlinkedUidKey);
    _unlinkedDisplayName = prefs.getString(_unlinkedNameKey);
    _guestAvatarId = prefs.getString(_guestAvatarKey) ?? 'avatar_01';
    _unlinkedAvatarId = prefs.getString(_unlinkedAvatarKey);

    final signedInUid = auth.currentUid;
    final String activeKey;
    final String statsKey;
    if (signedInUid != null) {
      activeKey = _linkedProgressKey(signedInUid);
      statsKey = '$_examStatsKeyPrefix$signedInUid';
    } else if (_unlinkedUid != null) {
      _localGuest = true;
      _avatarId = _unlinkedAvatarId ?? 'avatar_01';
      activeKey = _linkedProgressKey(_unlinkedUid!);
      statsKey = '$_examStatsKeyPrefix$_unlinkedUid';
    } else {
      _avatarId = _guestAvatarId;
      activeKey = _guestProgressKey;
      statsKey = '$_examStatsKeyPrefix' 'guest';
    }
    final oldStats = prefs.getString(_legacyExamStatsKey);
    if (prefs.containsKey(statsKey)) {
      await _loadExamStatsFromPrefs(statsKey);
      await prefs.remove(_legacyExamStatsKey);
    } else if (oldStats != null) {
      await prefs.setString(statsKey, oldStats);
      await prefs.remove(_legacyExamStatsKey);
      _loadExamStats(jsonDecode(oldStats) as Map<String, dynamic>);
    } else {
      _loadExamStats(null);
    }

    if (prefs.containsKey(activeKey)) {
      _loadProgress(activeKey);
      return;
    }

    final legacyProgress = prefs.getString(_progressKey);
    if (legacyProgress == null || legacyProgress.isEmpty) {
      _loadProgress(activeKey);
      return;
    }

    _loadProgress(_progressKey);
    await prefs.setString(activeKey, legacyProgress);
    await prefs.remove(_progressKey);
  }

  void clearDisplayNameIssue() {
    if (_displayNameIssue == null && !_displayNameConflict) return;
    _displayNameIssue = null;
    _displayNameConflict = false;
    notifyListeners();
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
      if (!_cloudWritesPaused && !auth.isAnonymous) {
        await _queueCloudPush(uid, _progress);
        await _publishStudyStats(uid);
      }
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

  Future<void> _persistLocal() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final String? activeKey;
    if (_unlinkedUid != null) {
      activeKey = _linkedProgressKey(_unlinkedUid!);
    } else if (_uid != null && !auth.isAnonymous) {
      activeKey = _linkedProgressKey(_uid!);
    } else if (_localGuest) {
      activeKey = _guestProgressKey;
    } else if (auth.currentUid != null && !auth.isAnonymous) {
      activeKey = _linkedProgressKey(auth.currentUid!);
    } else {
      activeKey = null;
    }
    final key = activeKey;
    if (key == null) return;
    final map = _progress.map((id, p) => MapEntry(id, p.toJson()));
    final contents = jsonEncode(map);
    final write = _pendingLocalWrite.then((_) async {
      await prefs.setString(key, contents);
    });
    _pendingLocalWrite = write.catchError((_) {});
    await write;
  }

  /// Đẩy tiến độ hiện tại lên Firestore nếu đang đăng nhập. Cố tình không
  /// `await` ở nơi gọi để không làm khựng UI khi lật thẻ liên tục; lỗi
  /// mạng ở đây không nên chặn việc học tiếp.
  void _pushIfSignedIn() {
    final uid = _uid ?? auth.currentUid;
    if (uid == null || auth.isAnonymous || _localGuest || _cloudWritesPaused) {
      return;
    }
    _queueCloudPush(uid, _progress).catchError((_) {});
    _publishStudyStats(uid).then((_) {
      _publicStatsIssue = null;
      notifyListeners();
    }).catchError((Object error) {
      _publicStatsIssue = auth.friendlyError(error);
      notifyListeners();
    });
  }

  Future<void> _queueCloudPush(
    String uid,
    Map<String, WordProgress> progress,
  ) {
    final snapshot = Map<String, WordProgress>.of(progress);
    final push = _pendingCloudPush.then((_) => _cloud.push(uid, snapshot));
    _pendingCloudPush = push.catchError((_) {});
    return push;
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
