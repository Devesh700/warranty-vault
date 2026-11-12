import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/app_lock_service.dart';
import 'core/constants.dart';
import 'core/crash_reporter.dart';
import 'core/env_config.dart';
import 'core/fcm_service.dart';
import 'core/firebase_sync_service.dart';
import 'core/notification_service.dart';
import 'core/subscription_service.dart';
import 'core/widgets/app_buttons.dart';
import 'core/widgets/warranty_vault_logo.dart';
import 'data/providers.dart';
import 'domain/enums.dart';
import 'domain/models.dart';
import 'l10n/generated/app_localizations.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReporter.install();
  await EnvConfig.load();
  runApp(
    const ProviderScope(
      child: WarrantyVaultApp(),
    ),
  );
}

class WarrantyVaultApp extends ConsumerStatefulWidget {
  const WarrantyVaultApp({super.key});

  @override
  ConsumerState<WarrantyVaultApp> createState() => _WarrantyVaultAppState();
}

class _WarrantyVaultAppState extends ConsumerState<WarrantyVaultApp>
    with WidgetsBindingObserver {
  bool _servicesInitialized = false;
  bool _unlocked = false;
  bool _authenticating = false;
  String? _lockError;
  bool _lockUnsupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleReminders();
      ref.read(subscriptionServiceProvider).refreshEntitlement();
    } else if (state == AppLifecycleState.paused) {
      final lockEnabled =
          ref.read(settingsStreamProvider).value?.appLockEnabled ?? false;
      if (lockEnabled) {
        setState(() {
          _unlocked = false;
          _lockError = null;
        });
      }
    }
  }

  Future<void> _initServicesOnce(Locale? locale) async {
    if (_servicesInitialized) return;
    _servicesInitialized = true;
    final notifs = ref.read(notificationServiceProvider);
    final router = ref.read(routerProvider);
    await notifs.initialize(
      onTapItem: (itemId) => router.push('/item/$itemId'),
    );
    await _rescheduleReminders(locale: locale);
    await ref.read(subscriptionServiceProvider).initialize();
    await ref.read(firebaseSyncServiceProvider).initialize();
    await ref.read(fcmServiceProvider).initialize(
      onNavigate: (route) => router.push(route),
      onForegroundBanner: (banner) {
        final messenger = rootScaffoldMessengerKey.currentState;
        if (messenger == null) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${banner.title}: ${banner.body}'),
            action: banner.route != null
                ? SnackBarAction(
                    label: 'View',
                    onPressed: () => router.push(banner.route!),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _rescheduleReminders({Locale? locale}) async {
    try {
      final resolvedLocale = locale ?? const Locale('en');
      final l10n = lookupAppLocalizations(resolvedLocale);
      await ref.read(notificationServiceProvider).rescheduleAll(l10n);
    } catch (_) {
      // Safe fallback in tests / unsupported platforms
    }
  }

  Future<void> _promptUnlock(AppLocalizations l10n) async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _lockError = null;
    });

    final result = await ref
        .read(appLockServiceProvider)
        .authenticateDetailed(l10n.unlockReason);

    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (result.isSuccess) {
        _unlocked = true;
        _lockError = null;
        _lockUnsupported = false;
      } else {
        _lockError = result.message;
        _lockUnsupported =
            result.outcome == BiometricAuthOutcome.notSupported;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final settings = settingsAsync.value ?? const UserSettings();

    final themeMode = switch (settings.theme) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };

    final Locale? locale = switch (settings.language) {
      AppLanguagePreference.system => null,
      AppLanguagePreference.en => const Locale('en'),
      AppLanguagePreference.hi => const Locale('hi'),
    };

    final isHindi = locale?.languageCode == 'hi';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServicesOnce(locale);
    });

    return MaterialApp.router(
      title: 'WarrantyVault',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light(isHindi: isHindi),
      darkTheme: AppTheme.dark(isHindi: isHindi),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clampedScaler = media.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
        );

        Widget content;
        if (settingsAsync.isLoading) {
          content = const _SplashLoadingView();
        } else if (settings.appLockEnabled && !_unlocked) {
          content = _AppLockGate(
            authenticating: _authenticating,
            errorMessage: _lockError,
            unsupportedOnDevice: _lockUnsupported,
            onUnlock: () => _promptUnlock(AppLocalizations.of(context)),
            onBypassUnsupported: () => setState(() => _unlocked = true),
          );
        } else {
          content = child ?? const SizedBox.shrink();
        }

        return MediaQuery(
          data: media.copyWith(textScaler: clampedScaler),
          child: content,
        );
      },
    );
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: WarrantyVaultLogo(
          size: 76,
          showWordmark: true,
        ),
      ),
    );
  }
}

class _AppLockGate extends StatefulWidget {
  const _AppLockGate({
    required this.authenticating,
    required this.errorMessage,
    required this.unsupportedOnDevice,
    required this.onUnlock,
    required this.onBypassUnsupported,
  });

  final bool authenticating;
  final String? errorMessage;
  final bool unsupportedOnDevice;
  final VoidCallback onUnlock;
  final VoidCallback onBypassUnsupported;

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onUnlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WarrantyVaultLogo(size: 72),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.unlockTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.unlockButton,
                  icon: Icons.fingerprint_rounded,
                  isLoading: widget.authenticating,
                  onPressed: widget.onUnlock,
                ),
                if (widget.unsupportedOnDevice) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextLinkButton(
                    label: 'Continue without device lock in browser',
                    onPressed: widget.onBypassUnsupported,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
