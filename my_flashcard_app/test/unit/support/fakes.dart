import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_flashcard_app/models/srs.dart';
import 'package:my_flashcard_app/models/vocab.dart';
import 'package:my_flashcard_app/services/cloud_progress_service.dart';
import 'package:my_flashcard_app/services/display_name_service.dart';
import 'package:my_flashcard_app/services/public_stats_service.dart';
import 'package:my_flashcard_app/services/vocab_repository.dart';

class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.currentUser});

  @override
  FakeUser? currentUser;
  String? createdEmail;
  String? createdPassword;
  String? signedInEmail;
  String? signedInPassword;

  @override
  Stream<User?> userChanges() => Stream<User?>.value(currentUser);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createdEmail = email;
    createdPassword = password;
    currentUser = FakeUser(
      uid: 'new-user',
      email: email,
      providerData: [FakeUserInfo('password')],
    );
    return FakeUserCredential(currentUser);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signedInEmail = email;
    signedInPassword = password;
    return FakeUserCredential(currentUser);
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {}

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.providerData = const [],
  });

  @override
  final String uid;
  @override
  final String? email;
  @override
  String? displayName;
  @override
  final bool isAnonymous;
  @override
  final List<UserInfo> providerData;
  bool wasDeleted = false;
  bool wasReauthenticated = false;
  AuthCredential? linkedCredential;
  Object? linkError;
  String? updatedPassword;

  @override
  Future<void> updateDisplayName(String? value) async {
    displayName = value;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> delete() async {
    wasDeleted = true;
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    if (linkError != null) throw linkError!;
    linkedCredential = credential;
    return FakeUserCredential(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    wasReauthenticated = true;
    return FakeUserCredential(this);
  }

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = password;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserInfo implements UserInfo {
  FakeUserInfo(this.providerId);

  @override
  final String providerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCloudProgressService implements CloudProgressService {
  final Map<String, Map<String, WordProgress>> progressByUid = {};
  final Map<String, String> avatarsByUid = {};
  final List<String> deletedUids = [];

  @override
  Future<Map<String, WordProgress>> fetch(String uid) async =>
      Map<String, WordProgress>.of(progressByUid[uid] ?? {});

  @override
  Future<void> push(String uid, Map<String, WordProgress> progress) async {
    progressByUid[uid] = Map<String, WordProgress>.of(progress);
  }

  @override
  Future<void> delete(String uid) async {
    deletedUids.add(uid);
    progressByUid.remove(uid);
    avatarsByUid.remove(uid);
  }

  @override
  Future<String?> fetchAvatarId(String uid) async => avatarsByUid[uid];

  @override
  Future<void> setAvatarId(String uid, String avatarId) async {
    avatarsByUid[uid] = avatarId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDisplayNameService implements DisplayNameService {
  final Map<String, String> namesToUids = {};
  final List<String> claimedNames = [];
  final List<String> releasedNames = [];

  @override
  Future<void> claim({
    required String displayName,
    required String uid,
    String? previousDisplayName,
  }) async {
    namesToUids[displayName.trim().toLowerCase()] = uid;
    claimedNames.add(displayName);
  }

  @override
  Future<void> release({
    required String displayName,
    required String uid,
  }) async {
    namesToUids.remove(displayName.trim().toLowerCase());
    releasedNames.add(displayName);
  }

  @override
  Future<String> uidForName(String displayName) async =>
      namesToUids[displayName.trim().toLowerCase()]!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePublicStatsService implements PublicStatsService {
  final List<String> deletedUids = [];
  int examCount = 0;
  int examWordsTotal = 0;
  int examCorrectTotal = 0;

  @override
  Future<void> deleteProfileData(String uid) async {
    deletedUids.add(uid);
  }

  @override
  Future<Map<String, int>> recordExamResult({
    required String uid,
    required String displayName,
    required String avatarId,
    required int wordCount,
    required int correctCount,
  }) async {
    examCount++;
    examWordsTotal += wordCount;
    examCorrectTotal += correctCount;
    return {
      'examCount': examCount,
      'examWordsTotal': examWordsTotal,
      'examCorrectTotal': examCorrectTotal,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVocabRepository implements VocabRepository {
  FakeVocabRepository(this.decks);

  final List<Deck> decks;

  @override
  Future<List<Deck>> load() async => decks;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
