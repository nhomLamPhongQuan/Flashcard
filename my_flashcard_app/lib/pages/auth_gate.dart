import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'account_page.dart';
import 'home_shell.dart';
import 'login_page.dart';

/// Tài khoản email hoặc phiên khách chỉ lưu trên thiết bị đều vào ứng dụng.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});
  final AuthService auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<String?> _uidChanges;

  @override
  void initState() {
    super.initState();
    _uidChanges = widget.auth.uidChanges;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StreamBuilder<String?>(
      stream: _uidChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final p = Palette.ofContext(context);
          return Scaffold(
            backgroundColor: p.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final uid = snapshot.data;
        if (uid == null && !state.localGuest) {
          return LoginPage(auth: widget.auth);
        }
        if (state.displayNameConflict) return const AccountPage();
        return const HomeShell();
      },
    );
  }
}
