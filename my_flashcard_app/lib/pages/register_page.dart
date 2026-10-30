import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.auth});
  final AuthService auth;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.register(
        displayName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = widget.auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.ofContext(context);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        title: const Text('Tạo Tài Khoản'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tạo tài khoản để lưu tiến độ học lâu dài',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: p.muted),
                  ),
                  const SizedBox(height: 24),
                  Panel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            maxLength: 60,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Tên'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Nhập tên của bạn'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (value) =>
                                (value == null || !value.contains('@'))
                                    ? 'Nhập email hợp lệ'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Mật khẩu'),
                            validator: (value) =>
                                (value == null || value.length < 6)
                                    ? 'Tối thiểu 6 ký tự'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Xác nhận mật khẩu'),
                            validator: (value) => value != _passwordCtrl.text
                                ? 'Mật khẩu xác nhận không khớp'
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
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Đăng ký'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
