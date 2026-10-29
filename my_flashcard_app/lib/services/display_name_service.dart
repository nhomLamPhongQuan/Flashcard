import 'package:cloud_firestore/cloud_firestore.dart';

class DisplayNameTakenException implements Exception {
  const DisplayNameTakenException();
}

class DisplayNameService {
  DisplayNameService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _reservation(String displayName) {
    final normalized = displayName.trim().toLowerCase();
    return _db.collection('usernames').doc(Uri.encodeComponent(normalized));
  }

  Future<void> claim({
    required String displayName,
    required String uid,
    String? previousDisplayName,
  }) async {
    final newReservation = _reservation(displayName);
    final previous = previousDisplayName?.trim();
    final oldReservation =
        previous == null || previous.isEmpty ? null : _reservation(previous);

    final newSnapshot = await newReservation.get();
    final currentOwner = newSnapshot.data()?['uid'];
    if (newSnapshot.exists && currentOwner != uid) {
      throw const DisplayNameTakenException();
    }

    await newReservation.set({'uid': uid});

    if (oldReservation != null && oldReservation.path != newReservation.path) {
      final oldSnapshot = await oldReservation.get();
      if (oldSnapshot.data()?['uid'] == uid) {
        await oldReservation.delete();
      }
    }
  }

  Future<void> release({
    required String displayName,
    required String uid,
  }) async {
    final reservation = _reservation(displayName);
    final snapshot = await reservation.get();
    if (snapshot.data()?['uid'] == uid) await reservation.delete();
  }
}
