import 'package:flutter/material.dart';

import '../models/avatar_catalog.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _working = false;
  String? _error;

  Future<void> _chooseAvatar(AppState state) async {
    final avatarId = await showDialog<String>(
      context: context,
      builder: (_) => _AvatarPickerDialog(selectedAvatarId: state.avatarId),
    );
    if (!mounted || avatarId == null || avatarId == state.avatarId) return;

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await state.selectAvatar(avatarId);
    } catch (error) {
      if (mounted) setState(() => _error = state.auth.friendlyError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editDisplayName(AppState state) async {
    final controller =
        TextEditingController(text: state.currentDisplayName ?? '');
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
    if (name == null || name.isEmpty || name == state.currentDisplayName) {
      return;
    }

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await state.updateDisplayName(name);
      state.clearDisplayNameIssue();
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
        title: const Text('Xác nhận đăng xuất'),
        content: Text(
          state.unlinkedSession
              ? 'Tài khoản chưa được liên kết và sẽ bị xóa khi đăng xuất'
              : state.auth.isAnonymous
                  ? 'Tài khoản khách và tiến độ của bạn vẫn được giữ trên thiết bị.'
                  : 'Tài khoản và tiến độ trên Firebase vẫn được giữ. Bản sao tiến độ trên thiết bị này sẽ bị xóa.',
        ),
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
      await state.signOut();
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

  Future<void> _linkAccount(AppState state) async {
    final details = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => const _LinkAccountDialog(),
    );
    if (details == null) return;

    setState(() {
      _error = null;
      _working = true;
    });
    try {
      await state.linkEmail(
        displayName: details.$1,
        email: details.$2,
        password: details.$3,
      );
      state.clearDisplayNameIssue();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã liên kết email với tài khoản.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = state.auth.friendlyError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _unlinkAccount(AppState state) async {
    final details = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _UnlinkAccountDialog(),
    );
    if (details == null) return;

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await state.unlinkEmailAccount(
        confirmationName: details.$1,
        password: details.$2,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tài khoản và dữ liệu Firebase đã được xóa. Tiến độ vẫn còn trên thiết bị.',
            ),
          ),
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
    final displayName = state.currentDisplayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? (state.unlinkedSession
            ? 'Tài khoản chưa liên kết'
            : auth.isAnonymous
                ? 'Tài khoản khách'
                : 'Chưa đặt tên')
        : displayName;
    final avatar = avatarOptionById(state.avatarId);

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
                  child: ClipOval(
                    child: Image.asset(
                      avatar.assetPath,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: palette.accent(state.lang),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _working ? null : () => _chooseAvatar(state),
                  icon: const Icon(Icons.face_retouching_natural_outlined),
                  label: const Text('Chọn ảnh đại diện'),
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
                      ? (state.unlinkedSession
                          ? 'Tài khoản chưa được liên kết'
                          : 'Đang dùng thử')
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
                          : (auth.isAnonymous
                              ? Icons.storage_outlined
                              : Icons.cloud_done_outlined),
                      color: palette.accent(state.lang),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.syncing
                            ? 'Đang đồng bộ tiến độ học...'
                            : (auth.isAnonymous
                                ? (state.unlinkedSession
                                    ? 'Dữ liệu tạm thời chỉ được lưu trên thiết bị này.'
                                    : 'Dữ liệu chỉ được lưu trên thiết bị này.')
                                : 'Tiến độ học được lưu trên thiết bị và đồng bộ khi đăng nhập.'),
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
          if (_error != null ||
              state.displayNameIssue != null ||
              state.localGuestIssue != null) ...[
            const SizedBox(height: 12),
            Text(
              _error ?? state.displayNameIssue ?? state.localGuestIssue!,
              style: const TextStyle(color: Color(0xFFD64550)),
              textAlign: TextAlign.center,
            ),
          ],
          if (state.localGuestIssue != null && auth.isAnonymous)
            TextButton(
              onPressed: _working
                  ? null
                  : () async {
                      setState(() => _working = true);
                      try {
                        await state.retryLegacyGuestCleanup();
                      } catch (error) {
                        if (mounted) {
                          setState(() {
                            _error = state.auth.friendlyError(error);
                          });
                        }
                      } finally {
                        if (mounted) setState(() => _working = false);
                      }
                    },
              child: const Text('Thử xóa dữ liệu Firebase lần nữa'),
            ),
          const SizedBox(height: 24),
          if (auth.isAnonymous) ...[
            FilledButton.tonalIcon(
              onPressed: _working ? null : () => _linkAccount(state),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Liên kết email và mật khẩu'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.tonalIcon(
            onPressed: _working ? null : () => _signOut(state),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
          if (!auth.isAnonymous) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _working ? null : () => _unlinkAccount(state),
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Hủy liên kết email'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarPickerDialog extends StatelessWidget {
  const _AvatarPickerDialog({required this.selectedAvatarId});

  final String selectedAvatarId;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.ofContext(context);
    return AlertDialog(
      title: const Text('Chọn ảnh đại diện'),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: avatarOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final avatar = avatarOptions[index];
            final selected = avatar.id == selectedAvatarId;
            return InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: () => Navigator.of(context).pop(avatar.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? palette.accent(AppScope.of(context).lang)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: Image.asset(
                      avatar.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: palette
                            .accent(AppScope.of(context).lang)
                            .withAlpha(36),
                        child: Icon(
                          Icons.person_rounded,
                          color: palette.accent(AppScope.of(context).lang),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
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

class _LinkAccountDialog extends StatefulWidget {
  const _LinkAccountDialog();

  @override
  State<_LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends State<_LinkAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo tài khoản email'),
      content: Form(
        key: _formKey,
        child: AutofillGroup(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Tên'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập tên của bạn'
                      : null,
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Nhập email hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Tối thiểu 6 ký tự'
                      : null,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration:
                      const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                  validator: (value) => value != _passwordController.text
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
          child: const Text('Liên kết'),
        ),
      ],
    );
  }
}

class _UnlinkAccountDialog extends StatefulWidget {
  const _UnlinkAccountDialog();

  @override
  State<_UnlinkAccountDialog> createState() => _UnlinkAccountDialogState();
}

class _UnlinkAccountDialogState extends State<_UnlinkAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      _nameController.text,
      _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final displayName = auth.currentDisplayName?.trim();
    final expectedName = displayName == null || displayName.isEmpty
        ? 'Chưa đặt tên'
        : displayName;

    return AlertDialog(
      title: const Text('Bạn có muốn hủy liên kết với tài khoản này?'),
      content: Form(
        key: _formKey,
        child: AutofillGroup(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến trình học vẫn sẽ được lưu trên máy tính của bạn',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tài khoản, tiến độ trên Firebase và tên đã đăng ký trên đám mây sẽ bị xóa.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nhập lại tên tài khoản'),
                  validator: (value) =>
                      value?.trim() != expectedName ? 'Tên không khớp' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Nhập mật khẩu'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nhập mật khẩu' : null,
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
          child: const Text('Hủy liên kết'),
        ),
      ],
    );
  }
}
