import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

//This is the account page, I move the themeMode to here. I think its better to stay here
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _working = false;
  String? _error;

  Future<void> _editDisplayName(AppState state) async {
    final controller =
        TextEditingController(text: state.auth.currentDisplayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tên hiển thị'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Tên'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == state.auth.currentDisplayName) {
      return;
    }

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await state.auth.updateDisplayName(name);
    } catch (error) {
      if (mounted) setState(() => _error = state.auth.friendlyError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signOut(AppState state) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Tiến độ học trên thiết bị này vẫn được giữ lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;

    try {
      await state.auth.signOut();
    } catch (error) {
      if (mounted) {
        setState(() => _error = state.auth.friendlyError(error));
      }
    }
  }

  Future<void> _changePassword(AppState state) async {
    final passwords = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (passwords == null) return;

    setState(() {
      _error = null;
      _working = true;
    });
    try {
      await state.auth.changePassword(
        currentPassword: passwords.$1,
        newPassword: passwords.$2,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đổi mật khẩu.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = state.auth.friendlyError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final auth = state.auth;
    final palette = Palette.ofContext(context);
    final displayName = auth.currentDisplayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? (auth.isAnonymous ? 'Tài khoản khách' : 'Chưa đặt tên')
        : displayName;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Panel(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: palette.accent(state.lang).withAlpha(36),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: palette.accent(state.lang),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isAnonymous
                      ? 'Đang dùng thử'
                      : (auth.currentEmail ?? 'Tài khoản email'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _working ? null : () => _editDisplayName(state),
                  icon: _working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                  label: Text(_working ? 'Đang xử lý...' : 'Sửa tên'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đồng bộ tiến độ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      state.syncing
                          ? Icons.sync_rounded
                          : Icons.cloud_done_outlined,
                      color: palette.accent(state.lang),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.syncing
                            ? 'Đang đồng bộ tiến độ học...'
                            : 'Tiến độ học được lưu trên thiết bị và đồng bộ khi đăng nhập.',
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giao diện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system, label: Text('Tự động')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Sáng')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Tối')),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (selection) =>
                      state.setThemeMode(selection.first),
                ),
              ],
            ),
          ),
          if (!auth.isAnonymous) ...[
            const SizedBox(height: 16),
            Panel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Đổi mật khẩu'),
                subtitle: const Text('Cập nhật mật khẩu đăng nhập'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _working ? null : () => _changePassword(state),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFD64550)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => _signOut(state),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      _currentPasswordController.text,
      _newPasswordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: _formKey,
        child: AutofillGroup(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration:
                      const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nhập mật khẩu hiện tại'
                      : null,
                ),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Mật khẩu phải có ít nhất 6 ký tự'
                      : null,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration:
                      const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                  validator: (value) => value != _newPasswordController.text
                      ? 'Mật khẩu xác nhận không khớp'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Cập nhật'),
        ),
      ],
    );
  }
}
