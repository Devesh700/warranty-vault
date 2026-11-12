import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics_service.dart';
import '../../core/app_lock_service.dart';
import '../../core/constants.dart';
import '../../core/export_service.dart';
import '../../core/fcm_service.dart';
import '../../core/firebase_sync_service.dart';
import '../../core/notification_service.dart';
import '../../core/subscription_service.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;

  Future<void> _updateAndSyncSetting(String key, String value) async {
    final repo = ref.read(warrantyRepositoryProvider);
    await repo.updateSetting(key, value);
    final updated = await repo.getSettings();
    await ref.read(firebaseSyncServiceProvider).syncSettings(updated);
  }

  Future<void> _pickReminderTime(
    UserSettings settings,
    AppLocalizations l10n,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null || !mounted) return;
    final repo = ref.read(warrantyRepositoryProvider);
    await repo.updateSetting('reminderHour', picked.hour.toString());
    await repo.updateSetting('reminderMinute', picked.minute.toString());
    final updated = await repo.getSettings();
    await ref.read(firebaseSyncServiceProvider).syncSettings(updated);
    await ref.read(notificationServiceProvider).rescheduleAll(l10n);
  }

  Future<void> _toggleReminderKind(
    String key,
    bool value,
    AppLocalizations l10n,
  ) async {
    await _updateAndSyncSetting(key, value.toString());
    await ref.read(notificationServiceProvider).rescheduleAll(l10n);
  }

  Future<void> _toggleAppLock(bool value, AppLocalizations l10n) async {
    final result = await ref
        .read(appLockServiceProvider)
        .authenticateDetailed(l10n.unlockReason);
    if (!mounted) return;

    // Allow disabling on unsupported browsers/devices if lock was synced from elsewhere
    final canDisableUnsupported =
        !value && result.outcome == BiometricAuthOutcome.notSupported;
    if (!result.isSuccess && !canDisableUnsupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Biometric authentication could not be verified.',
          ),
        ),
      );
      return;
    }

    await _updateAndSyncSetting('appLockEnabled', value.toString());
  }

  Future<void> _exportAll(AppLocalizations l10n) async {
    setState(() => _exporting = true);
    try {
      await ref.read(exportServiceProvider).exportAndShare();
      ref.read(analyticsServiceProvider).exportUsed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.genericErrorHeadline}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAllData(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllConfirmTitle),
        content: Text(l10n.deleteAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(firebaseSyncServiceProvider).deleteAllRemote();
    await ref.read(warrantyRepositoryProvider).deleteAllData();
    await ref
        .read(warrantyRepositoryProvider)
        .updateSetting('onboardingDone', 'true');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allDataDeleted)),
      );
    }
  }

  Future<void> _restorePurchases(AppLocalizations l10n) async {
    ref.read(analyticsServiceProvider).restoreTapped();
    final restored =
        await ref.read(subscriptionServiceProvider).restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? l10n.purchaseRestored : l10n.noActiveSubscription,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final fbSync = ref.watch(firebaseSyncServiceProvider);
    final fcm = ref.watch(fcmServiceProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSettings),
      ),
      body: settingsAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          onRetry: () => ref.invalidate(settingsStreamProvider),
        ),
        data: (settings) {
          final formattedTime = TimeOfDay(
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
          ).format(context);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // 1. Reminders
              SectionHeader(title: l10n.settingsSectionReminders),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded),
                      title: Text(l10n.reminderTimeLabel),
                      trailing: Text(
                        formattedTime,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _pickReminderTime(settings, l10n),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: Text(l10n.remind30DaysToggle),
                      value: settings.remindD30,
                      onChanged: (v) =>
                          _toggleReminderKind('remindD30', v, l10n),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: Text(l10n.remind7DaysToggle),
                      value: settings.remindD7,
                      onChanged: (v) =>
                          _toggleReminderKind('remindD7', v, l10n),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: Text(l10n.remind1DayToggle),
                      value: settings.remindD1,
                      onChanged: (v) =>
                          _toggleReminderKind('remindD1', v, l10n),
                    ),
                    const Divider(height: 1),
                    ValueListenableBuilder<FcmStatus>(
                      valueListenable: fcm.statusNotifier,
                      builder: (ctx, fcmStatus, _) {
                        final String subtitle;
                        if (!fcmStatus.isInitialized) {
                          subtitle = 'Add Firebase keys to enable cloud push';
                        } else if (!fcmStatus.isSupported) {
                          subtitle = 'Push alerts unavailable in this browser';
                        } else if (fcmStatus.isAuthorized) {
                          subtitle = fcmStatus.hasToken
                              ? 'Device registered for push notifications'
                              : 'Push notifications enabled';
                        } else {
                          subtitle = 'Tap to enable cloud push alerts';
                        }
                        return ListTile(
                          leading: Icon(
                            fcmStatus.isAuthorized
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_none_rounded,
                            color: fcmStatus.isAuthorized
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          title: const Text('Push Notifications (FCM)'),
                          subtitle: Text(subtitle),
                          trailing: fcmStatus.isSupported &&
                                  !fcmStatus.isAuthorized
                              ? TextButton(
                                  onPressed: () async {
                                    await fcm.requestPermissionAndRegister();
                                  },
                                  child: const Text('Enable'),
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Appearance
              SectionHeader(title: l10n.settingsSectionAppearance),
              Card(
                child: RadioGroup<AppThemePreference>(
                  groupValue: settings.theme,
                  onChanged: (v) {
                    if (v != null) {
                      _updateAndSyncSetting('theme', v.name);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.themeSystem),
                        value: AppThemePreference.system,
                      ),
                      const Divider(height: 1),
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.themeLight),
                        value: AppThemePreference.light,
                      ),
                      const Divider(height: 1),
                      RadioListTile<AppThemePreference>(
                        title: Text(l10n.themeDark),
                        value: AppThemePreference.dark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Language
              SectionHeader(title: l10n.settingsSectionLanguage),
              Card(
                child: RadioGroup<AppLanguagePreference>(
                  groupValue: settings.language,
                  onChanged: (v) {
                    if (v != null) {
                      _updateAndSyncSetting('language', v.name);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<AppLanguagePreference>(
                        title: Text(l10n.languageSystem),
                        value: AppLanguagePreference.system,
                      ),
                      const Divider(height: 1),
                      RadioListTile<AppLanguagePreference>(
                        title: Text(l10n.languageEnglish),
                        value: AppLanguagePreference.en,
                      ),
                      const Divider(height: 1),
                      RadioListTile<AppLanguagePreference>(
                        title: Text(l10n.languageHindi),
                        value: AppLanguagePreference.hi,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Security
              SectionHeader(title: l10n.settingsSectionSecurity),
              Card(
                child: SwitchListTile.adaptive(
                  title: Text(l10n.appLockLabel),
                  value: settings.appLockEnabled,
                  onChanged: (v) => _toggleAppLock(v, l10n),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Data & Firebase Cloud Sync
              SectionHeader(title: l10n.settingsSectionData),
              Card(
                child: Column(
                  children: [
                    ValueListenableBuilder<CloudSyncStatus>(
                      valueListenable: fbSync.statusNotifier,
                      builder: (ctx, status, _) {
                        final String subtitle;
                        if (!status.isConfigured) {
                          subtitle =
                              'Add Firebase keys to .env to enable cloud sync';
                        } else if (status.lastError != null) {
                          subtitle = 'Sync error: ${status.lastError}';
                        } else if (status.isSyncing) {
                          subtitle = 'Syncing with Firebase...';
                        } else if (status.email != null) {
                          subtitle = 'Synced as ${status.email}';
                        } else if (status.uid != null) {
                          subtitle = 'Synced (anonymous vault)';
                        } else {
                          subtitle = 'Sign in to sync across devices';
                        }
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                status.isConfigured
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_off_outlined,
                                color: status.isConfigured
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              title: const Text('Firebase Cloud Sync'),
                              subtitle: Text(subtitle),
                              trailing: status.isSyncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : (status.isConfigured
                                      ? IconButton(
                                          tooltip: 'Sync now',
                                          icon: const Icon(Icons.sync_rounded),
                                          onPressed: fbSync.syncAll,
                                        )
                                      : null),
                            ),
                            if (status.isConfigured) ...[
                              const Divider(height: 1),
                              if (status.isAnonymous || status.email == null) ...[
                                ListTile(
                                  leading: const Icon(Icons.login_rounded),
                                  title: const Text('Sign in to existing vault'),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => context.push('/auth?mode=signin'),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.person_add_outlined),
                                  title: const Text('Create cloud vault account'),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => context.push('/auth?mode=create'),
                                ),
                              ] else
                                ListTile(
                                  leading: const Icon(Icons.logout_rounded),
                                  title: const Text('Sign out'),
                                  onTap: fbSync.signOut,
                                ),
                            ] else ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.login_rounded),
                                title: const Text('Cloud Vault Sign In'),
                                subtitle: const Text('Preview account sign-in & vault setup'),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () => context.push('/auth?mode=signin'),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: Text(l10n.keepUnmodifiedCopy),
                      value: settings.keepUnmodifiedCopy,
                      onChanged: (v) => _updateAndSyncSetting(
                        'keepUnmodifiedCopy',
                        v.toString(),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(
                        _exporting ? l10n.exportingData : l10n.exportAllData,
                      ),
                      trailing: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _exporting ? null : () => _exportAll(l10n),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        l10n.deleteAllData,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onTap: () => _deleteAllData(l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. Subscription
              SectionHeader(title: l10n.settingsSectionSubscription),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.workspace_premium_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        isPro
                            ? l10n.subscriptionStatusPro
                            : l10n.subscriptionStatusFree,
                      ),
                      trailing: isPro
                          ? null
                          : Text(
                              l10n.upgradeToPro,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      onTap: () => context.push('/paywall?trigger=settings'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(l10n.cloudBackupTitle),
                      trailing: Text(l10n.comingSoon),
                      onTap: () => context.push('/paywall?trigger=cloud_backup'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.group_outlined),
                      title: Text(l10n.familyVaultTitle),
                      trailing: Text(l10n.comingSoon),
                      onTap: () => context.push('/paywall?trigger=family_vault'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_rounded),
                      title: Text(l10n.restorePurchases),
                      onTap: () => _restorePurchases(l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 7. About
              SectionHeader(title: l10n.settingsSectionAbout),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.privacyPolicy),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/legal/privacy'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l10n.termsOfService),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/legal/terms'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.mail_outline_rounded),
                      title: Text(l10n.contactSupport),
                      onTap: () => launchUrl(
                        Uri.parse('mailto:support@warrantyvault.app'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline_rounded),
                      title: Text(l10n.rateApp),
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.warrantyvault.warranty_vault',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(l10n.appVersion),
                      trailing: const Text('1.0.0'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
