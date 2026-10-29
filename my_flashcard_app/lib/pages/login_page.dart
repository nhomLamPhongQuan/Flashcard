import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import 'register_page.dart';

/// Màn hình đăng nhập, hoặc "Dùng thử không cần tài khoản"
/// (chỉ lưu dữ liệu trên thiết bị, không tạo tài khoản Firebase).
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

  Future<void> _continueAsGuest() async {
    final state = AppScope.of(context);
    if (state.hasSavedGuest) {
      final choice = await showDialog<_GuestChoice>(
        context: context,
        builder: (_) => const _ExistingGuestDialog(),
      );
      if (!mounted || choice == null) return;
      if (choice == _GuestChoice.continueExisting) {
        await _runAuthAction(state.continueLocalGuest);
        return;
      }
    }

    final displayName = await showDialog<String>(
      context: context,
      builder: (_) => const _GuestNameDialog(),
    );
    if (!mounted || displayName == null) return;
    await _runAuthAction(() async {
      await state.startLocalGuest(
        displayName,
        replaceExisting: state.hasSavedGuest,
      );
    });
  }

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
                    'Khách chỉ lưu dữ liệu trên thiết bị. Tạo hoặc liên kết tài khoản email để đồng bộ tiến độ.',
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

class _GuestNameDialog extends StatefulWidget {
  const _GuestNameDialog();

  @override
  State<_GuestNameDialog> createState() => _GuestNameDialogState();
}

class _GuestNameDialogState extends State<_GuestNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dùng thử với tư cách khách'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Tên của bạn'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nhập tên để tiếp tục'
              : null,
          onFieldSubmitted: (_) => _continue(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _continue,
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }
}

enum _GuestChoice { continueExisting, replaceExisting }

class _ExistingGuestDialog extends StatelessWidget {
  const _ExistingGuestDialog();

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).savedGuestName;
    return AlertDialog(
      title: const Text('Đã có tài khoản khách trên thiết bị'),
      content: Text(
        'Bạn muốn tiếp tục với ${name?.isNotEmpty == true ? name : 'tài khoản khách hiện có'} '
        'hay tạo tài khoản khách mới? Tạo mới sẽ thay thế toàn bộ tiến độ khách cũ.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(_GuestChoice.replaceExisting),
          child: const Text('Tạo mới'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_GuestChoice.continueExisting),
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }
}
