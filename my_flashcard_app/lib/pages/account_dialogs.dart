import 'package:flutter/material.dart';

import '../models/avatar_catalog.dart';
import '../models/public_stats.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class StatsPrivacyDraft {
  const StatsPrivacyDraft({
    required this.mode,
    required this.allowedViewerNames,
    required this.blockedViewerNames,
  });

  final StatsPrivacyMode mode;
  final List<String> allowedViewerNames;
  final List<String> blockedViewerNames;
}

class StatsPrivacyDialog extends StatefulWidget {
  const StatsPrivacyDialog({super.key, required this.settings});

  final StatsPrivacySettings settings;

  @override
  State<StatsPrivacyDialog> createState() => _StatsPrivacyDialogState();
}

class _StatsPrivacyDialogState extends State<StatsPrivacyDialog> {
  late StatsPrivacyMode _mode = widget.settings.mode;
  late final TextEditingController _allowedController = TextEditingController(
      text: widget.settings.allowedViewerNames.join('\n'));
  late final TextEditingController _blockedController = TextEditingController(
      text: widget.settings.blockedViewerNames.join('\n'));

  @override
  void dispose() {
    _allowedController.dispose();
    _blockedController.dispose();
    super.dispose();
  }

  List<String> _namesFrom(TextEditingController controller) =>
      controller.text.split('\n').map((name) => name.trim()).toList();

  void _save() {
    Navigator.of(context).pop(
      StatsPrivacyDraft(
        mode: _mode,
        allowedViewerNames: _namesFrom(_allowedController),
        blockedViewerNames: _namesFrom(_blockedController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listController = _mode == StatsPrivacyMode.open
        ? _blockedController
        : _allowedController;
    final isBlockedList = _mode == StatsPrivacyMode.open;

    return AlertDialog(
      title: const Text('Quyền riêng tư thống kê'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<StatsPrivacyMode>(
                showSelectedIcon: false,
                segments: [
                  for (final mode in StatsPrivacyMode.values)
                    ButtonSegment(value: mode, label: Text(mode.label)),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 8),
              Text(_mode.description),
              if (_mode != StatsPrivacyMode.cloaked) ...[
                const SizedBox(height: 8),
                Text(
                  isBlockedList ? 'Blacklist' : 'Whitelist',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isBlockedList
                      ? 'Một tên tài khoản trên mỗi dòng. Những người này không thể xem thống kê của bạn.'
                      : 'Một tên tài khoản trên mỗi dòng. Chỉ những người này có thể xem thống kê của bạn.',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: listController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tên tài khoản',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class AvatarPickerDialog extends StatelessWidget {
  const AvatarPickerDialog({super.key, required this.selectedAvatarId});

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

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
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

class LinkAccountDialog extends StatefulWidget {
  const LinkAccountDialog({super.key});

  @override
  State<LinkAccountDialog> createState() => _LinkAccountDialogState();
}

class _LinkAccountDialogState extends State<LinkAccountDialog> {
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

class UnlinkAccountDialog extends StatefulWidget {
  const UnlinkAccountDialog({super.key});

  @override
  State<UnlinkAccountDialog> createState() => _UnlinkAccountDialogState();
}

class _UnlinkAccountDialogState extends State<UnlinkAccountDialog> {
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
