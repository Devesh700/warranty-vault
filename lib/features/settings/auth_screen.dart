import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/firebase_sync_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/warranty_vault_logo.dart';

enum AuthMode { signIn, create }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = AuthMode.signIn,
  });

  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AuthMode _mode;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    if (_busy || _mode == mode) return;
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found')) {
      return 'Incorrect email or password. Please double-check and try again.';
    }
    if (lower.contains('email-already-in-use') ||
        lower.contains('credential-already-in-use')) {
      return 'An account already exists with this email. Try signing in instead.';
    }
    if (lower.contains('weak-password')) {
      return 'Choose a stronger password with at least 6 characters.';
    }
    if (lower.contains('network-request-failed')) {
      return 'Network unavailable. Check your internet connection and retry.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    return raw;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final fb = ref.read(firebaseSyncServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final err = _mode == AuthMode.create
        ? await fb.createAccountWithEmail(email, password)
        : await fb.signInWithEmail(email, password);

    if (!mounted) return;

    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == AuthMode.create
                ? 'Cloud vault linked & synced'
                : 'Signed in & synced',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/settings');
      }
      return;
    }

    setState(() {
      _busy = false;
      _errorMessage = _friendlyAuthError(err);
    });
  }

  Future<void> _forgotPassword() async {
    final resetEmailCtrl = TextEditingController(
      text: _emailController.text.trim(),
    );
    final theme = Theme.of(context);
    String? dialogErr;
    bool sending = false;

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email and we will send a password reset link.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (dialogErr != null) ...[
                const SizedBox(height: 10),
                Text(
                  dialogErr!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = resetEmailCtrl.text.trim();
                      if (!email.contains('@') || !email.contains('.')) {
                        setDialogState(
                          () => dialogErr = 'Enter a valid email address.',
                        );
                        return;
                      }
                      setDialogState(() {
                        sending = true;
                        dialogErr = null;
                      });
                      final err = await ref
                          .read(firebaseSyncServiceProvider)
                          .sendPasswordReset(email);
                      if (!ctx.mounted) return;
                      if (err == null) {
                        Navigator.of(ctx).pop(true);
                      } else {
                        setDialogState(() {
                          sending = false;
                          dialogErr = _friendlyAuthError(err);
                        });
                      }
                    },
              child: Text(sending ? 'Sending...' : 'Send link'),
            ),
          ],
        ),
      ),
    );
    resetEmailCtrl.dispose();

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent. Check your inbox.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fbSync = ref.watch(firebaseSyncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<CloudSyncStatus>(
        valueListenable: fbSync.statusNotifier,
        builder: (context, fbStatus, _) {
          return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero branding card
                  Center(
                    child: WarrantyVaultLogo(
                      size: 72,
                      showWordmark: true,
                      subtitle: _mode == AuthMode.signIn
                          ? 'Sign in to restore and sync your warranty vault across devices'
                          : 'Link an email so your bills & reminders follow you everywhere',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Segmented mode toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E242E)
                          : const Color(0xFFE8EEF7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeTab(
                            label: 'Sign In',
                            selected: _mode == AuthMode.signIn,
                            onTap: () => _switchMode(AuthMode.signIn),
                          ),
                        ),
                        Expanded(
                          child: _ModeTab(
                            label: 'Create Account',
                            selected: _mode == AuthMode.create,
                            onTap: () => _switchMode(AuthMode.create),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Main form card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!fbStatus.isConfigured) ...[
                              _StatusBanner(
                                color: AppColors.warning,
                                icon: Icons.cloud_off_rounded,
                                message:
                                    'Cloud keys are not configured in .env yet. Your vault remains safely saved locally on this device.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_busy,
                              obscureText: _obscurePassword,
                              textInputAction: _mode == AuthMode.create
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: _mode == AuthMode.create
                                  ? const [AutofillHints.newPassword]
                                  : const [AutofillHints.password],
                              onFieldSubmitted: _mode == AuthMode.signIn
                                  ? (_) => _submit()
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: _mode == AuthMode.create
                                    ? 'At least 6 characters'
                                    : 'Enter your password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final v = value ?? '';
                                if (v.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_mode == AuthMode.create) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmController,
                                enabled: !_busy,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon:
                                      const Icon(Icons.verified_user_outlined),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (_mode != AuthMode.create) return null;
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (_mode == AuthMode.signIn)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy || !fbStatus.isInitialized
                                      ? null
                                      : _forgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              )
                            else
                              const SizedBox(height: 18),

                            if (_errorMessage != null) ...[
                              _StatusBanner(
                                color: AppColors.danger,
                                icon: Icons.error_outline_rounded,
                                message: _errorMessage!,
                              ),
                              const SizedBox(height: 14),
                            ],

                            PrimaryButton(
                              label: _mode == AuthMode.create
                                  ? 'Create Account & Sync'
                                  : 'Sign In',
                              icon: _mode == AuthMode.create
                                  ? Icons.cloud_upload_outlined
                                  : Icons.login_rounded,
                              isLoading: _busy,
                              onPressed: fbStatus.isInitialized ? _submit : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Security reassurance footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Local-first vault • Cloud sync uses Firebase Auth & TLS',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
          );
        },
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF161B22) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
