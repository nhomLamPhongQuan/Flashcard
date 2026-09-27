import 'package:firebase_auth/firebase_auth.dart';

/// Bọc FirebaseAuth: phần còn lại của app chỉ thấy `uidChanges` / các hàm
/// đăng nhập-đăng ký, không đụng trực tiếp vào kiểu `User` của Firebase.
/// Sau này muốn đổi backend (Supabase, tự viết...) chỉ cần viết lại class
/// này, không phải sửa AppState hay UI.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  /// Phát ra uid mỗi khi trạng thái đăng nhập đổi; null nghĩa là chưa
  /// đăng nhập (kể cả chưa từng vào app lần nào).
  Stream<String?> get uidChanges => _auth.authStateChanges().map((u) => u?.uid);

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  /// true nếu đang dùng phiên "khách" (chưa gắn email/mật khẩu thật).
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Dùng thử app không cần tài khoản. Vẫn có 1 uid ẩn danh riêng để đồng
  /// bộ tiến độ lên Firestore, và có thể nâng cấp lên tài khoản thật sau
  /// bằng [linkEmail] mà không mất dữ liệu đã học.
  Future<void> continueAsGuest() => _auth.signInAnonymously();

  /// Gắn email/mật khẩu vào phiên ẩn danh hiện tại (giữ nguyên uid, nên
  /// tiến độ đã đồng bộ trước đó không bị mất).
  Future<void> linkEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Chưa có phiên đăng nhập để nâng cấp.');
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await user.linkWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  /// Dịch mã lỗi Firebase sang câu tiếng Việt dễ hiểu cho người dùng.
  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'email-already-in-use':
          return 'Email này đã được đăng ký.';
        case 'weak-password':
          return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng.';
        case 'network-request-failed':
          return 'Không có kết nối mạng.';
        default:
          return 'Có lỗi xảy ra (${error.code}).';
      }
    }
    return 'Có lỗi không xác định xảy ra.';
  }
}
