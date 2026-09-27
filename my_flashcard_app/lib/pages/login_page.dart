import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

enum _Mode { signIn, register }

/// Màn hình đăng nhập / đăng ký, hoặc "Dùng thử không cần tài khoản"
/// (đăng nhập ẩn danh — vẫn đồng bộ được, chỉ là chưa gắn email).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});
  final AuthService auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_mode == _Mode.signIn) {
        await widget.auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await widget.auth.register(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
      // Đăng nhập/đăng ký thành công -> AuthGate tự chuyển màn hình qua
      // stream uidChanges, không cần tự điều hướng ở đây.
    } catch (e) {
      setState(() => _error = widget.auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.continueAsGuest();
    } catch (e) {
      setState(() => _error = widget.auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);
    final isSignIn = _mode == _Mode.signIn;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Từ vựng Anh · Nhật · Hàn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSignIn
                        ? 'Đăng nhập để đồng bộ tiến độ học trên mọi thiết bị'
                        : 'Tạo tài khoản để lưu tiến độ học lâu dài',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: p.muted),
                  ),
                  const SizedBox(height: 28),
                  Panel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Nhập email hợp lệ'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Mật khẩu'),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Tối thiểu 6 ký tự'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Color(0xFFD64550), fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(isSignIn ? 'Đăng nhập' : 'Đăng ký'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _mode = isSignIn ? _Mode.register : _Mode.signIn;
                              _error = null;
                            }),
                    child: Text(
                      isSignIn
                          ? 'Chưa có tài khoản? Đăng ký'
                          : 'Đã có tài khoản? Đăng nhập',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Divider(color: p.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('hoặc',
                            style: TextStyle(fontSize: 12, color: p.muted)),
                      ),
                      Expanded(child: Divider(color: p.line)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loading ? null : _continueAsGuest,
                    child: const Text('Dùng thử không cần tài khoản'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Học thử vẫn được lưu trên máy; nếu muốn đồng bộ nhiều thiết bị, bạn có thể tạo tài khoản sau trong mục Tiến độ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: p.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
