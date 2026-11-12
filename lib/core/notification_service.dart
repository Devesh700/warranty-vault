import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../data/providers.dart';
import '../data/repositories/warranty_repository.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'date_logic.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.kind,
    required this.fireAt,
    required this.notificationId,
  });

  final ReminderKind kind;
  final DateTime fireAt;
  final int notificationId;
}

int deterministicNotificationId(String itemId, ReminderKind kind) {
  final key = '${itemId}_${kind.name}';
  var hash = 0x811c9dc5;
  for (final code in key.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

/// Pure function computing 30d, 7d, 1d reminder timestamps at user's preferred time,
/// skipping disabled kinds, lifetime/no-warranty items, and past times.
List<PlannedReminder> computeReminderPlansForItem(
  WarrantyItem item,
  UserSettings settings, {
  DateTime? now,
}) {
  if (item.isLifetime) return const [];
  if (item.warrantyMonths <= 0 && item.extendedWarrantyEndDate == null) {
    return const [];
  }

  final currentNow = now ?? DateTime.now();
  final end = dateOnly(item.effectiveEndDate);

  final specs = <(ReminderKind, int, bool)>[
    (ReminderKind.d30, 30, settings.remindD30),
    (ReminderKind.d7, 7, settings.remindD7),
    (ReminderKind.d1, 1, settings.remindD1),
  ];

  final result = <PlannedReminder>[];
  for (final (kind, daysBefore, enabled) in specs) {
    if (!enabled) continue;
    final targetDate = end.subtract(Duration(days: daysBefore));
    final fireAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      settings.reminderHour,
      settings.reminderMinute,
    );
    if (!fireAt.isAfter(currentNow)) continue;
    result.add(
      PlannedReminder(
        kind: kind,
        fireAt: fireAt,
        notificationId: deterministicNotificationId(item.id, kind),
      ),
    );
  }
  return result;
}

class NotificationService {
  NotificationService(this._repo);

  final WarrantyRepository _repo;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'warranty_reminders';
  bool _initialized = false;
  void Function(String itemId)? _onTapItem;

  Future<void> initialize({
    required void Function(String itemId) onTapItem,
  }) async {
    _onTapItem = onTapItem;
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _refreshLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'WarrantyVault',
      appUserModelId: 'com.warrantyvault.app',
      guid: 'c3d8c4d0-6f28-4c5c-96f9-4b10a24b3f77',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          final payload = details.payload;
          if (payload != null && payload.isNotEmpty) {
            _onTapItem?.call(payload);
          }
        },
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'Warranty Reminders',
          description: 'Expiry alerts and service warranty updates',
          importance: Importance.high,
        ),
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _onTapItem?.call(payload);
        }
      }
    } catch (_) {
      // Safe fallback in headless tests / unsupported desktop runners
    }

    _initialized = true;
  }

  Future<void> _refreshLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return (await android?.areNotificationsEnabled()) ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final perms = await ios?.checkPermissions();
        return perms?.isEnabled ?? true;
      }
    } catch (_) {}
    return true;
  }

  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return (await android?.requestNotificationsPermission()) ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return (await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            false;
      }
    } catch (_) {}
    return true;
  }

  Future<void> cancelRemindersForItem(String itemId) async {
    final existing = await _repo.getRemindersForItem(itemId);
    for (final rem in existing) {
      try {
        await _plugin.cancel(id: rem.notificationId);
      } catch (_) {}
    }
    await _repo.replaceRemindersForItem(itemId, const []);
  }

  Future<void> syncRemindersForItem(
    WarrantyItem item,
    UserSettings settings,
    AppLocalizations l10n,
  ) async {
    await cancelRemindersForItem(item.id);

    final plans = computeReminderPlansForItem(item, settings);
    if (plans.isEmpty) return;

    const uuid = Uuid();
    final dbReminders = <ItemReminder>[];

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        l10n.notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (final plan in plans) {
      final body = switch (plan.kind) {
        ReminderKind.d30 => l10n.notif30Days(item.name),
        ReminderKind.d7 => l10n.notif7Days(item.name),
        ReminderKind.d1 => l10n.notif1Day(item.name),
      };

      try {
        final scheduled = tz.TZDateTime.from(plan.fireAt, tz.local);
        await _plugin.zonedSchedule(
          id: plan.notificationId,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: l10n.appName,
          body: body,
          payload: item.id,
        );
      } catch (_) {
        // Ignore platform scheduling failures in test/desktop environments
      }

      dbReminders.add(
        ItemReminder(
          id: uuid.v4(),
          itemId: item.id,
          fireAt: plan.fireAt,
          kind: plan.kind,
          notificationId: plan.notificationId,
        ),
      );
    }

    await _repo.replaceRemindersForItem(item.id, dbReminders);
  }

  Future<void> rescheduleAll(AppLocalizations l10n) async {
    await _refreshLocalTimezone();
    final items = await _repo.getAllItems();
    final settings = await _repo.getSettings();
    for (final item in items) {
      await syncRemindersForItem(item, settings, l10n);
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Warranty Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(warrantyRepositoryProvider));
});
