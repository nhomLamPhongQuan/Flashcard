import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/srs.dart';

/// Đồng bộ tiến độ học (hộp Leitner của từng từ) lên Cloud Firestore.
///
/// Mỗi tài khoản có đúng 1 document: `users/{uid}`, field `progress` là
/// map id-từ -> {box, next} — cùng cấu trúc JSON với bản lưu local trong
/// shared_preferences, nên merge giữa 2 bên rất đơn giản.
class CloudProgressService {
  CloudProgressService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Future<Map<String, WordProgress>> fetch(String uid) async {
    final snap = await _doc(uid).get();
    final raw = snap.data()?['progress'] as Map<String, dynamic>?;
    if (raw == null) return {};
    return raw.map(
      (id, v) => MapEntry(
          id, WordProgress.fromJson(Map<String, dynamic>.from(v as Map))),
    );
  }

  Future<void> push(String uid, Map<String, WordProgress> progress) async {
    final data = progress.map((id, p) => MapEntry(id, p.toJson()));
    await _doc(uid).set(
      {'progress': data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
