import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import 'register_page.dart';

/// Màn hình đăng nhập, hoặc "Dùng thử không cần tài khoản"
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
    final email = _emailCtrl.text.trim();
    await _runAuthAction(() => widget.auth.signIn(email, _passwordCtrl.text));
  }

  Future<void> _continueAsGuest() =>
      _runAuthAction(widget.auth.continueAsGuest);

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = widget.auth.friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //So I change the code a little bit to make it easier to read and also split it into 2 different pages - login and register.
  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);

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
                    'Đăng nhập để đồng bộ tiến độ học trên mọi thiết bị',
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
                                  : const Text('Đăng nhập'),
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
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => RegisterPage(auth: widget.auth),
                              ),
                            ),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
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
