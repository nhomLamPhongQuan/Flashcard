import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'login_page.dart';

/// Màn hình gác cổng: chưa có phiên đăng nhập (kể cả ẩn danh) -> LoginPage,
/// đã có phiên -> vào thẳng app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: auth.uidChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final p = Palette.ofContext(context);
          return Scaffold(
            backgroundColor: p.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final uid = snapshot.data;
        if (uid == null) return LoginPage(auth: auth);
        return const HomeShell();
      },
    );
  }
}
