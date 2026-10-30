import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/public_stats.dart';
import 'display_name_service.dart';

class PublicStatsService {
  PublicStatsService({
    FirebaseFirestore? db,
    DisplayNameService? displayNames,
  })  : _db = db ?? FirebaseFirestore.instance,
        _displayNames = displayNames ?? DisplayNameService(db: db);

  final FirebaseFirestore _db;
  final DisplayNameService _displayNames;

  DocumentReference<Map<String, dynamic>> _stats(String uid) =>
      _db.collection('public_stats').doc(uid);

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('user_settings').doc(uid);

  Future<StatsPrivacySettings> ensurePrivacySettings(String uid) async {
    final ref = _settings(uid);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, {
          'statsPrivacyMode': StatsPrivacyMode.cloaked.name,
          'allowedViewerUids': <String>[],
          'allowedViewerNames': <String>[],
          'blockedViewerUids': <String>[],
          'blockedViewerNames': <String>[],
        });
        return const StatsPrivacySettings();
      }

      final data = snapshot.data()!;
      return StatsPrivacySettings(
        mode: StatsPrivacyMode.fromValue(
          data['statsPrivacyMode'] as String?,
        ),
        allowedViewerNames: _stringList(data['allowedViewerNames']),
        blockedViewerNames: _stringList(data['blockedViewerNames']),
      );
    });
  }

  Future<void> savePrivacySettings({
    required String uid,
    required StatsPrivacyMode mode,
    required List<String> allowedViewerNames,
    required List<String> allowedViewerUids,
    required List<String> blockedViewerNames,
    required List<String> blockedViewerUids,
  }) =>
      _settings(uid).set({
        'statsPrivacyMode': mode.name,
        'allowedViewerNames': allowedViewerNames,
        'allowedViewerUids': allowedViewerUids,
        'blockedViewerNames': blockedViewerNames,
        'blockedViewerUids': blockedViewerUids,
      }, SetOptions(merge: true));

  Future<void> ensureStatsDocument({
    required String uid,
    required String displayName,
    required Map<String, dynamic> initialStats,
  }) async {
    final ref = _stats(uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, {
          'displayName': displayName,
          'masteredCount': initialStats['masteredCount'] ?? 0,
          'dueCount': initialStats['dueCount'] ?? 0,
          'totalWords': initialStats['totalWords'] ?? 0,
          'decks': initialStats['decks'] ?? <Map<String, dynamic>>[],
          'examCount': initialStats['examCount'] ?? 0,
          'examWordsTotal': initialStats['examWordsTotal'] ?? 0,
          'examCorrectTotal': initialStats['examCorrectTotal'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (snapshot.data()?['displayName'] != displayName) {
        transaction.set(
          ref,
          {
            'displayName': displayName,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<Map<String, dynamic>?> fetchOwnStats(String uid) async {
    final snapshot = await _stats(uid).get();
    return snapshot.data();
  }

  Future<void> updateStudyStats({
    required String uid,
    required String displayName,
    required int masteredCount,
    required int dueCount,
    required int totalWords,
    required List<Map<String, dynamic>> decks,
  }) =>
      _stats(uid).set({
        'displayName': displayName,
        'masteredCount': masteredCount,
        'dueCount': dueCount,
        'totalWords': totalWords,
        'decks': decks,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<Map<String, int>> recordExamResult({
    required String uid,
    required String displayName,
    required int wordCount,
    required int correctCount,
  }) {
    final ref = _stats(uid);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? <String, dynamic>{};
      final values = <String, int>{
        'examCount': (data['examCount'] as int? ?? 0) + 1,
        'examWordsTotal': (data['examWordsTotal'] as int? ?? 0) + wordCount,
        'examCorrectTotal':
            (data['examCorrectTotal'] as int? ?? 0) + correctCount,
      };
      transaction.set(
        ref,
        {
          'displayName': displayName,
          ...values,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return values;
    });
  }

  Future<PublicStats?> findByName(String displayName) async {
    final uid = await _displayNames.uidForName(displayName);
    final snapshot = await _stats(uid).get();
    final data = snapshot.data();
    return data == null ? null : PublicStats.fromJson(data);
  }

  Future<void> deleteProfileData(String uid) async {
    await Future.wait([
      _stats(uid).delete(),
      _settings(uid).delete(),
    ]);
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
