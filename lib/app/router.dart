import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/add_item/add_item_screen.dart';
import '../features/add_item/add_source_sheet.dart';
import '../features/broke_help/broke_help_screen.dart';
import '../features/home/expiring_screen.dart';
import '../features/home/home_screen.dart';
import '../features/item_detail/item_detail_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/settings/auth_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);

  ref.listen(settingsStreamProvider, (_, _) {
    refreshNotifier.refresh();
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/items',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final settingsAsync = ref.read(settingsStreamProvider);
      if (!settingsAsync.hasValue) return null;

      final onboardingDone = settingsAsync.value!.onboardingDone;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingDone && !isOnboarding) {
        return '/onboarding';
      }
      if (onboardingDone && isOnboarding) {
        return '/items';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            onAddPressed: () => showAddItemSourceSheet(context),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/items',
                builder: (context, state) => HomeScreen(
                  onAddPressed: () => showAddItemSourceSheet(context),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expiring',
                builder: (context, state) => const ExpiringScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final resumeDraft = state.uri.queryParameters['draft'] == '1';
          final launchArgs = state.extra is AddItemLaunchArgs
              ? state.extra as AddItemLaunchArgs
              : null;
          return AddItemScreen(
            resumeDraft: resumeDraft,
            launchArgs: launchArgs,
          );
        },
      ),
      GoRoute(
        path: '/edit/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddItemScreen(editItemId: id);
        },
      ),
      GoRoute(
        path: '/item/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ItemDetailScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/broke-help/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BrokeHelpScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final trigger = state.uri.queryParameters['trigger'] ?? 'general';
          return PaywallScreen(trigger: trigger);
        },
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final modeParam = state.uri.queryParameters['mode'];
          return AuthScreen(
            initialMode:
                modeParam == 'create' ? AuthMode.create : AuthMode.signIn,
          );
        },
      ),
      GoRoute(
        path: '/legal/privacy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const LegalScreen(type: LegalDocType.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const LegalScreen(type: LegalDocType.terms),
      ),
    ],
  );
});
