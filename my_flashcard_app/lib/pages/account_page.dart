import 'package:flutter/material.dart';

import '../models/avatar_catalog.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/page_title_bar.dart';
import 'account_dialogs.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _working = false;
  String? _error;

  Future<T?> _showNeutralDialog<T>({
    required WidgetBuilder builder,
  }) {
    final theme = AppTheme.neutralizeAccents(
      Theme.of(context),
      Palette.ofContext(context),
    );
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Theme(
        data: theme,
        child: builder(dialogContext),
      ),
    );
  }

  Future<void> _chooseAvatar(AppState state) async {
    final avatarId = await _showNeutralDialog<String>(
      builder: (_) => AvatarPickerDialog(selectedAvatarId: state.avatarId),
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
    final name = await _showNeutralDialog<String>(
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
    final shouldSignOut = await _showNeutralDialog<bool>(
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
    final passwords = await _showNeutralDialog<(String, String)>(
      builder: (_) => const ChangePasswordDialog(),
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
    final details = await _showNeutralDialog<(String, String, String)>(
      builder: (_) => const LinkAccountDialog(),
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
    final details = await _showNeutralDialog<(String, String)>(
      builder: (_) => const UnlinkAccountDialog(),
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

  Future<void> _editStatsPrivacy(AppState state) async {
    final settings = await _showNeutralDialog<StatsPrivacyDraft>(
      builder: (_) => StatsPrivacyDialog(settings: state.statsPrivacy),
    );
    if (settings == null) return;

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await state.saveStatsPrivacy(
        mode: settings.mode,
        allowedViewerNames: settings.allowedViewerNames,
        blockedViewerNames: settings.blockedViewerNames,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật quyền riêng tư thống kê.')),
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

    return Theme(
      data: AppTheme.neutralizeAccents(Theme.of(context), palette),
      child: Scaffold(
        appBar: AppBar(
          title: PageTitleBar(
            title: 'Tài Khoản',
            icon: Icons.person_rounded,
            accent: palette.muted,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: palette.muted.withAlpha(36),
                    child: ClipOval(
                      child: Image.asset(
                        avatar.assetPath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          color: palette.muted,
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
            if (!auth.isAnonymous && !state.unlinkedSession) ...[
              const SizedBox(height: 16),
              Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Quyền riêng tư thống kê'),
                  subtitle: Text(
                    state.statsPrivacyReady
                        ? '${state.statsPrivacy.mode.label} · '
                            '${state.statsPrivacy.mode.description}'
                        : state.statsPrivacyIssue != null
                            ? 'Không thể tải cài đặt: '
                                '${state.statsPrivacyIssue}'
                            : 'Đang tải cài đặt quyền riêng tư...',
                    style: state.statsPrivacyIssue != null
                        ? TextStyle(color: Theme.of(context).colorScheme.error)
                        : null,
                  ),
                  trailing: state.statsPrivacyLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : state.statsPrivacyIssue != null
                          ? IconButton(
                              tooltip: 'Thử tải lại cài đặt quyền riêng tư',
                              onPressed: () => state.retryStatsPrivacyLoad(),
                              icon: const Icon(Icons.refresh_rounded),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                  onTap: _working || !state.statsPrivacyReady
                      ? null
                      : () => _editStatsPrivacy(state),
                ),
              ),
            ],
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
                        color: palette.muted,
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
                      ButtonSegment(
                          value: ThemeMode.light, label: Text('Sáng')),
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
                state.localGuestIssue != null ||
                state.publicStatsIssue != null) ...[
              const SizedBox(height: 12),
              Text(
                _error ??
                    state.displayNameIssue ??
                    state.localGuestIssue ??
                    state.publicStatsIssue!,
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
      ),
    );
  }
}
