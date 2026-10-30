import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_progress_service.dart';
import 'display_name_service.dart';
import 'public_stats_service.dart';

/// Bọc FirebaseAuth: phần còn lại của app chỉ thấy `uidChanges` / các hàm
/// đăng nhập-đăng ký, không đụng trực tiếp vào kiểu `User` của Firebase.
/// Sau này muốn đổi backend (Supabase, tự viết...) chỉ cần viết lại class
/// này, không phải sửa AppState hay UI.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    CloudProgressService? cloudProgress,
    DisplayNameService? displayNames,
    PublicStatsService? publicStats,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _cloudProgress = cloudProgress ?? CloudProgressService(),
        _displayNames = displayNames ?? DisplayNameService(),
        _publicStats = publicStats ?? PublicStatsService();
  final FirebaseAuth _auth;
  final CloudProgressService _cloudProgress;
  final DisplayNameService _displayNames;
  final PublicStatsService _publicStats;

  /// Emits the UID for sign-in and profile changes; null means signed out.
  Stream<String?> get uidChanges =>
      _auth.userChanges().map((user) => user?.uid);

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail {
    final user = _auth.currentUser;
    return user?.providerData
                .any((provider) => provider.providerId == 'password') ==
            true
        ? user?.email
        : null;
  }

  String? get currentDisplayName => _auth.currentUser?.displayName;

  /// App guest mode includes accounts with no linked sign-in provider.
  bool get isAnonymous {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous || user.providerData.isEmpty;
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase chưa trả về tài khoản mới đăng ký.');
    }
    var nameClaimed = false;
    try {
      await _displayNames.claim(displayName: displayName, uid: user.uid);
      nameClaimed = true;
      await user.updateDisplayName(displayName);
      await user.reload();
      if (_auth.currentUser?.displayName != displayName) {
        throw StateError('Firebase did not save the account display name.');
      }
    } catch (error) {
      Object? cleanupError;
      if (nameClaimed) {
        try {
          await _displayNames.release(displayName: displayName, uid: user.uid);
        } catch (error) {
          cleanupError = error;
        }
      }
      try {
        await user.delete();
      } catch (error) {
        cleanupError ??= error;
      }
      if (cleanupError != null) {
        throw StateError(
          '${friendlyError(error)} '
          'Đăng ký thất bại và không thể dọn dữ liệu tạm: $cleanupError',
        );
      }
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Tạo tài khoản email từ chế độ khách chỉ lưu dữ liệu trên thiết bị.
  Future<void> linkEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      await register(
        displayName: displayName,
        email: email,
        password: password,
      );
      return;
    }
    final previousName = user.displayName;
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await _displayNames.claim(displayName: displayName, uid: user.uid);
    try {
      await user.updateDisplayName(displayName);
    } catch (error) {
      try {
        await _displayNames.release(displayName: displayName, uid: user.uid);
      } catch (cleanupError) {
        throw StateError(
          'Không thể cập nhật tên: ${friendlyError(error)} '
          'Không thể dọn tên đã đặt trước: $cleanupError',
        );
      }
      rethrow;
    }
    try {
      await user.linkWithCredential(credential);
    } catch (error) {
      Object? cleanupError;
      try {
        await user.updateDisplayName(previousName);
      } catch (error) {
        cleanupError = error;
      }
      try {
        await _displayNames.release(displayName: displayName, uid: user.uid);
      } catch (error) {
        cleanupError ??= error;
      }
      if (cleanupError != null) {
        throw StateError(
          'Liên kết thất bại: ${friendlyError(error)} '
          'Không thể khôi phục toàn bộ dữ liệu: $cleanupError',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Chưa có phiên đăng nhập để cập nhật tên.');
    }
    final previousName = user.displayName;
    if (!isAnonymous) {
      await _displayNames.claim(
        displayName: displayName,
        uid: user.uid,
        previousDisplayName: previousName,
      );
    }
    try {
      await user.updateDisplayName(displayName);
    } catch (error) {
      if (!isAnonymous) {
        try {
          if (previousName == null || previousName.trim().isEmpty) {
            await _displayNames.release(
                displayName: displayName, uid: user.uid);
          } else {
            await _displayNames.claim(
              displayName: previousName,
              uid: user.uid,
              previousDisplayName: displayName,
            );
          }
        } catch (cleanupError) {
          throw StateError(
            'Không thể cập nhật tên: ${friendlyError(error)} '
            'Không thể khôi phục tên trước đó: $cleanupError',
          );
        }
      }
      rethrow;
    }
    await user.reload();
  }

  Future<void> unlinkEmailAccount({
    required String confirmationName,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || isAnonymous || user.email == null) {
      throw StateError('Tài khoản này chưa liên kết email và mật khẩu.');
    }
    final hasPasswordProvider =
        user.providerData.any((provider) => provider.providerId == 'password');
    if (!hasPasswordProvider) {
      throw StateError('Tài khoản này chưa liên kết email và mật khẩu.');
    }

    final displayName = user.displayName?.trim();
    final expectedName = displayName == null || displayName.isEmpty
        ? 'Chưa đặt tên'
        : displayName;
    if (confirmationName.trim() != expectedName) {
      throw StateError('Tên xác nhận không khớp.');
    }
    if (password.isEmpty) throw StateError('Nhập mật khẩu để tiếp tục.');

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );

    var reservationReleased = false;
    try {
      await _cloudProgress.delete(user.uid);
      await _publicStats.deleteProfileData(user.uid);
      if (displayName != null && displayName.isNotEmpty) {
        await _displayNames.release(displayName: displayName, uid: user.uid);
        reservationReleased = true;
      }
      await user.delete();
    } catch (error) {
      if (reservationReleased && _auth.currentUser?.uid == user.uid) {
        try {
          await _displayNames.claim(
            displayName: displayName!,
            uid: user.uid,
          );
        } catch (restoreError) {
          throw StateError(
            'Không thể xóa dữ liệu Firebase: ${friendlyError(error)} '
            'Không thể khôi phục tên đã đặt: $restoreError',
          );
        }
      }
      rethrow;
    }
  }

  /// Removes Firebase data for anonymous/providerless users from older app
  /// versions, preserving their already-local progress and display name.
  Future<String?> removeLegacyGuestAccount() async {
    final user = _auth.currentUser;
    if (user == null || !isAnonymous) return null;

    final displayName = user.displayName;
    await _cloudProgress.delete(user.uid);
    await _publicStats.deleteProfileData(user.uid);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await _displayNames.release(
        displayName: displayName,
        uid: user.uid,
      );
    }
    await user.delete();
    return displayName;
  }

  Future<void> ensureCurrentDisplayNameClaimed() async {
    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim();
    if (user == null ||
        isAnonymous ||
        displayName == null ||
        displayName.isEmpty) {
      return;
    }
    await _displayNames.claim(displayName: displayName, uid: user.uid);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null ||
        email == null ||
        isAnonymous ||
        !user.providerData
            .any((provider) => provider.providerId == 'password')) {
      throw StateError('Tài khoản này chưa dùng đăng nhập bằng email.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Dịch mã lỗi Firebase sang câu tiếng Việt dễ hiểu cho người dùng.
  String friendlyError(Object error) {
    if (error is DisplayNameTakenException) {
      return 'Tên này đã được sử dụng. Hãy chọn tên khác.';
    }
    if (error is DisplayNameNotFoundException) {
      return 'Không tìm thấy tài khoản có tên này.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'Email và mật khẩu chưa được bật trong Firebase Authentication.';
        case 'app-not-authorized':
          return 'Ứng dụng này chưa được phép dùng Firebase Authentication.';
        case 'network-request-failed':
          return 'Không có kết nối mạng.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'email-already-in-use':
        case 'credential-already-in-use':
          return 'Email này đã được đăng ký.';
        case 'weak-password':
          return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng.';
        case 'requires-recent-login':
          return 'Vui lòng đăng nhập lại rồi thử đổi mật khẩu.';
        default:
          final message = error.message;
          return message == null || message.isEmpty
              ? 'Lỗi Firebase Authentication: ${error.code}.'
              : 'Lỗi Firebase Authentication (${error.code}): $message';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firebase từ chối yêu cầu (permission-denied). '
              'Kiểm tra quyền truy cập và các quy tắc Firebase đã triển khai.';
        case 'unavailable':
          return 'Không có kết nối mạng.';
        case 'unauthenticated':
          return 'Firebase yêu cầu xác thực. Hãy đăng nhập lại rồi thử lần nữa.';
        case 'failed-precondition':
          return 'Firebase chưa được thiết lập đầy đủ: ${error.message ?? error.code}';
        default:
          return error.message == null || error.message!.isEmpty
              ? 'Lỗi Firebase (${error.code}).'
              : 'Lỗi Firebase (${error.code}): ${error.message}';
      }
    }
    if (error is StateError) return error.message.toString();
    final details = error.toString();
    final conciseDetails =
        details.length > 300 ? '${details.substring(0, 300)}...' : details;
    return 'Lỗi ${error.runtimeType}: $conciseDetails';
  }
}
