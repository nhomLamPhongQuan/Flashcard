import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flashcard_app/services/auth_service.dart';

import 'support/fakes.dart';

void main() {
  group('AuthService', () {
    test('registers email account and reserves the display name', () async {
      final platform = FakeFirebaseAuth();
      final displayNames = FakeDisplayNameService();
      final service = AuthService(
        auth: platform,
        cloudProgress: FakeCloudProgressService(),
        displayNames: displayNames,
        publicStats: FakePublicStatsService(),
      );

      await service.register(
        displayName: 'Learner',
        email: 'learner@example.com',
        password: 'secret1',
      );

      expect(platform.createdEmail, 'learner@example.com');
      expect(platform.createdPassword, 'secret1');
      expect(platform.currentUser?.displayName, 'Learner');
      expect(displayNames.namesToUids['learner'], 'new-user');
    });

    test('signs in using the supplied email and password', () async {
      final platform = FakeFirebaseAuth();
      final service = AuthService(
        auth: platform,
        cloudProgress: FakeCloudProgressService(),
        displayNames: FakeDisplayNameService(),
        publicStats: FakePublicStatsService(),
      );

      await service.signIn('person@example.com', 'password');

      expect(platform.signedInEmail, 'person@example.com');
      expect(platform.signedInPassword, 'password');
    });

    test('links email credentials to an existing guest user', () async {
      final guest = FakeUser(uid: 'guest-1', isAnonymous: true);
      final platform = FakeFirebaseAuth(currentUser: guest);
      final displayNames = FakeDisplayNameService();
      final service = AuthService(
        auth: platform,
        cloudProgress: FakeCloudProgressService(),
        displayNames: displayNames,
        publicStats: FakePublicStatsService(),
      );

      await service.linkEmail(
        displayName: 'Linked learner',
        email: 'linked@example.com',
        password: 'secret1',
      );

      expect(guest.displayName, 'Linked learner');
      expect(guest.linkedCredential, isNotNull);
      expect(displayNames.namesToUids['linked learner'], 'guest-1');
    });

    test('releases the reserved name when guest linking fails', () async {
      final guest = FakeUser(
        uid: 'guest-1',
        displayName: 'Guest',
        isAnonymous: true,
      )..linkError = FirebaseAuthException(code: 'credential-already-in-use');
      final displayNames = FakeDisplayNameService();
      final service = AuthService(
        auth: FakeFirebaseAuth(currentUser: guest),
        cloudProgress: FakeCloudProgressService(),
        displayNames: displayNames,
        publicStats: FakePublicStatsService(),
      );

      await expectLater(
        service.linkEmail(
          displayName: 'New name',
          email: 'existing@example.com',
          password: 'secret1',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(guest.displayName, 'Guest');
      expect(displayNames.namesToUids, isEmpty);
      expect(displayNames.releasedNames, ['New name']);
    });

    test('requires confirmation and deletes linked cloud data on unlink',
        () async {
      final user = FakeUser(
        uid: 'linked-1',
        email: 'linked@example.com',
        displayName: 'Learner',
        providerData: [FakeUserInfo('password')],
      );
      final cloud = FakeCloudProgressService();
      final stats = FakePublicStatsService();
      final displayNames = FakeDisplayNameService();
      final service = AuthService(
        auth: FakeFirebaseAuth(currentUser: user),
        cloudProgress: cloud,
        displayNames: displayNames,
        publicStats: stats,
      );

      await expectLater(
        service.unlinkEmailAccount(
          confirmationName: 'Wrong name',
          password: 'secret1',
        ),
        throwsA(isA<StateError>()),
      );
      expect(user.wasDeleted, isFalse);

      await service.unlinkEmailAccount(
        confirmationName: 'Learner',
        password: 'secret1',
      );

      expect(user.wasReauthenticated, isTrue);
      expect(user.wasDeleted, isTrue);
      expect(cloud.deletedUids, ['linked-1']);
      expect(stats.deletedUids, ['linked-1']);
      expect(displayNames.releasedNames, ['Learner']);
    });

    test('classifies providerless users as guests and translates auth errors',
        () {
      final service = AuthService(
        auth: FakeFirebaseAuth(
          currentUser: FakeUser(uid: 'guest', providerData: const []),
        ),
        cloudProgress: FakeCloudProgressService(),
        displayNames: FakeDisplayNameService(),
        publicStats: FakePublicStatsService(),
      );

      expect(service.isAnonymous, isTrue);
      expect(
        service.friendlyError(FirebaseAuthException(code: 'wrong-password')),
        'Email hoặc mật khẩu không đúng.',
      );
      expect(
        service.friendlyError(
            FirebaseAuthException(code: 'network-request-failed')),
        'Không có kết nối mạng.',
      );
    });
  });
}
