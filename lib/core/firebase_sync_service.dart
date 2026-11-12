import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/repositories/warranty_repository.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import 'crash_reporter.dart';
import 'env_config.dart';
import 'local_file_store.dart';

class CloudSyncStatus {
  const CloudSyncStatus({
    this.isConfigured = false,
    this.isInitialized = false,
    this.isSyncing = false,
    this.uid,
    this.email,
    this.isAnonymous = true,
    this.lastSyncedAt,
    this.lastError,
  });

  final bool isConfigured;
  final bool isInitialized;
  final bool isSyncing;
  final String? uid;
  final String? email;
  final bool isAnonymous;
  final DateTime? lastSyncedAt;
  final String? lastError;

  CloudSyncStatus copyWith({
    bool? isConfigured,
    bool? isInitialized,
    bool? isSyncing,
    String? uid,
    bool clearUid = false,
    String? email,
    bool clearEmail = false,
    bool? isAnonymous,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return CloudSyncStatus(
      isConfigured: isConfigured ?? this.isConfigured,
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      uid: clearUid ? null : (uid ?? this.uid),
      email: clearEmail ? null : (email ?? this.email),
      isAnonymous: isAnonymous ?? this.isAnonymous,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class FirebaseSyncService {
  FirebaseSyncService(this._repo);

  final WarrantyRepository _repo;
  StreamSubscription<User?>? _authSub;

  final ValueNotifier<CloudSyncStatus> statusNotifier =
      ValueNotifier(const CloudSyncStatus());

  bool get isReady =>
      statusNotifier.value.isInitialized &&
      FirebaseAuth.instance.currentUser != null;

  String? get _uid =>
      statusNotifier.value.isInitialized ? FirebaseAuth.instance.currentUser?.uid : null;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> initialize() async {
    await EnvConfig.load();
    final options = EnvConfig.toFirebaseOptions();
    if (options == null) {
      statusNotifier.value = const CloudSyncStatus(
        isConfigured: false,
        isInitialized: false,
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }

      final auth = FirebaseAuth.instance;
      _updateAuthStatus();
      await _authSub?.cancel();
      _authSub = auth.authStateChanges().listen((_) => _updateAuthStatus());

      if (auth.currentUser != null) {
        await syncAll();
      }
    } catch (e) {
      statusNotifier.value = CloudSyncStatus(
        isConfigured: true,
        isInitialized: false,
        lastError: e.toString(),
      );
    }
  }

  void _updateAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    statusNotifier.value = statusNotifier.value.copyWith(
      isConfigured: true,
      isInitialized: true,
      uid: user?.uid,
      clearUid: user == null,
      email: user?.email,
      clearEmail: user?.email == null,
      isAnonymous: user?.isAnonymous ?? true,
      clearError: true,
    );
  }

  Future<String?> signInWithEmail(String email, String password) async {
    if (!statusNotifier.value.isInitialized) return 'Firebase not configured';
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _updateAuthStatus();
      await syncAll();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createAccountWithEmail(String email, String password) async {
    if (!statusNotifier.value.isInitialized) return 'Firebase not configured';
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.isAnonymous) {
        final cred = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await current.linkWithCredential(cred);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }
      _updateAuthStatus();
      await syncAll();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    if (!statusNotifier.value.isInitialized) return 'Firebase not configured';
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  String? _activeFcmToken;

  Future<void> saveFcmToken(String token, {required String platform}) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    _activeFcmToken = trimmed;
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final tokenId = Uri.encodeComponent(trimmed);
      await doc.collection('fcm_tokens').doc(tokenId).set({
        'token': trimmed,
        'platform': platform,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> deleteFcmToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final tokenId = Uri.encodeComponent(trimmed);
      await doc.collection('fcm_tokens').doc(tokenId).delete();
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> signOut() async {
    if (!statusNotifier.value.isInitialized) return;
    final tokenToRemove = _activeFcmToken;
    if (tokenToRemove != null) {
      await deleteFcmToken(tokenToRemove);
    }
    await FirebaseAuth.instance.signOut();
    _activeFcmToken = null;
    _updateAuthStatus();
  }

  void dispose() {
    _authSub?.cancel();
    statusNotifier.dispose();
  }

  Future<void> syncItem(WarrantyItem item) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('items').doc(item.id).set({
        'id': item.id,
        'name': item.name,
        'brand': item.brand,
        'model': item.model,
        'serialNumber': item.serialNumber,
        'category': item.category.name,
        'purchaseDate': item.purchaseDate.toIso8601String(),
        'price': item.price,
        'currency': item.currency,
        'storeName': item.storeName,
        'warrantyMonths': item.warrantyMonths,
        'warrantyEndDate': item.warrantyEndDate.toIso8601String(),
        'extendedWarrantyEndDate':
            item.extendedWarrantyEndDate?.toIso8601String(),
        'isLifetime': item.isLifetime,
        'notes': item.notes,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      });
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> syncAttachment(ItemAttachment att) async {
    final doc = _userDoc;
    final uid = _uid;
    if (doc == null || uid == null) return;
    try {
      String? downloadUrl;
      final storagePath = 'users/$uid/attachments/${att.itemId}/${att.id}.jpg';
      if (!att.localPath.startsWith('http')) {
        final bytes = await LocalFileStore.readBytes(att.localPath);
        if (bytes != null && bytes.isNotEmpty) {
          final ref = FirebaseStorage.instance.ref(storagePath);
          await ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          downloadUrl = await ref.getDownloadURL();
        }
      } else {
        downloadUrl = att.localPath;
      }

      await doc.collection('attachments').doc(att.id).set({
        'id': att.id,
        'itemId': att.itemId,
        'type': att.type.name,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'createdAt': att.createdAt.toIso8601String(),
      });
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> syncRemindersForItem(
    String itemId,
    List<ItemReminder> reminders,
  ) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      final col = doc.collection('reminders');
      final existing = await col.where('itemId', isEqualTo: itemId).get();
      for (final d in existing.docs) {
        await d.reference.delete();
      }
      for (final r in reminders) {
        await col.doc(r.id).set({
          'id': r.id,
          'itemId': r.itemId,
          'fireAt': r.fireAt.toIso8601String(),
          'kind': r.kind.name,
          'notificationId': r.notificationId,
        });
      }
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> deleteItemRemote(String itemId) async {
    final doc = _userDoc;
    final uid = _uid;
    if (doc == null || uid == null) return;
    try {
      await doc.collection('items').doc(itemId).delete();
      final atts = await doc
          .collection('attachments')
          .where('itemId', isEqualTo: itemId)
          .get();
      for (final d in atts.docs) {
        final storagePath = d.data()['storagePath'] as String?;
        if (storagePath != null) {
          try {
            await FirebaseStorage.instance.ref(storagePath).delete();
          } catch (e, st) {
            CrashReporter.recordNonFatal(e, st);
          }
        }
        await d.reference.delete();
      }
      final rems = await doc
          .collection('reminders')
          .where('itemId', isEqualTo: itemId)
          .get();
      for (final d in rems.docs) {
        await d.reference.delete();
      }
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> syncSettings(UserSettings settings) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.collection('settings').doc('preferences').set({
        'theme': settings.theme.name,
        'language': settings.language.name,
        'reminderHour': settings.reminderHour,
        'reminderMinute': settings.reminderMinute,
        'remindD30': settings.remindD30,
        'remindD7': settings.remindD7,
        'remindD1': settings.remindD1,
        'appLockEnabled': settings.appLockEnabled,
        'onboardingDone': settings.onboardingDone,
        'keepUnmodifiedCopy': settings.keepUnmodifiedCopy,
        'isProCached': settings.isProCached,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  Future<void> deleteAllRemote() async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      for (final colName in [
        'items',
        'attachments',
        'reminders',
        'settings',
        'fcm_tokens',
      ]) {
        final snap = await doc.collection(colName).get();
        for (final d in snap.docs) {
          final storagePath = d.data()['storagePath'] as String?;
          if (storagePath != null) {
            try {
              await FirebaseStorage.instance.ref(storagePath).delete();
            } catch (e, st) {
              CrashReporter.recordNonFatal(e, st);
            }
          }
          await d.reference.delete();
        }
      }
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
    }
  }

  /// Bidirectional sync using latest updatedAt wins.
  Future<void> syncAll() async {
    final doc = _userDoc;
    if (doc == null) return;
    statusNotifier.value =
        statusNotifier.value.copyWith(isSyncing: true, clearError: true);

    try {
      // 1. Pull remote items and merge with local (latest updatedAt wins)
      final localItems = await _repo.getAllItems();
      final localById = {for (final i in localItems) i.id: i};
      final remoteSnap = await doc.collection('items').get();

      for (final d in remoteSnap.docs) {
        final remote = _itemFromMap(d.data());
        if (remote == null) continue;
        final local = localById[remote.id];
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _repo.upsertItem(remote);
        }
      }

      // 2. Push newer or missing local items
      final refreshedLocal = await _repo.getAllItems();
      final remoteUpdatedAt = <String, DateTime>{};
      for (final d in remoteSnap.docs) {
        final u = DateTime.tryParse(d.data()['updatedAt'] as String? ?? '');
        if (u != null) remoteUpdatedAt[d.id] = u;
      }
      for (final item in refreshedLocal) {
        final ru = remoteUpdatedAt[item.id];
        if (ru == null || item.updatedAt.isAfter(ru)) {
          await syncItem(item);
        }
      }

      // 3. Merge attachments
      final localAtts = await _repo.getAllAttachments();
      final localAttIds = localAtts.map((a) => a.id).toSet();
      final remoteAttSnap = await doc.collection('attachments').get();
      final remoteAttIds = <String>{};

      for (final d in remoteAttSnap.docs) {
        remoteAttIds.add(d.id);
        final data = d.data();
        if (!localAttIds.contains(d.id)) {
          final url = data['downloadUrl'] as String?;
          final itemId = data['itemId'] as String?;
          if (url != null && itemId != null) {
            await _repo.addAttachment(
              ItemAttachment(
                id: d.id,
                itemId: itemId,
                type: AttachmentType.values.firstWhere(
                  (t) => t.name == data['type'],
                  orElse: () => AttachmentType.other,
                ),
                localPath: url,
                createdAt: DateTime.tryParse(
                        data['createdAt'] as String? ?? '') ??
                    DateTime.now(),
              ),
            );
          }
        }
      }

      for (final att in localAtts) {
        if (!remoteAttIds.contains(att.id)) {
          await syncAttachment(att);
        }
      }

      // 4. Push local settings if remote settings doc doesn't exist yet
      final settingsDoc =
          await doc.collection('settings').doc('preferences').get();
      if (!settingsDoc.exists) {
        final localSettings = await _repo.getSettings();
        await syncSettings(localSettings);
      }

      statusNotifier.value = statusNotifier.value.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      statusNotifier.value = statusNotifier.value.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    }
  }

  WarrantyItem? _itemFromMap(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final name = data['name'] as String?;
    final purchaseStr = data['purchaseDate'] as String?;
    final endStr = data['warrantyEndDate'] as String?;
    if (id == null || name == null || purchaseStr == null || endStr == null) {
      return null;
    }
    final purchaseDate = DateTime.tryParse(purchaseStr);
    final warrantyEndDate = DateTime.tryParse(endStr);
    if (purchaseDate == null || warrantyEndDate == null) return null;

    return WarrantyItem(
      id: id,
      name: name,
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      serialNumber: data['serialNumber'] as String?,
      category: ItemCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => ItemCategory.other,
      ),
      purchaseDate: purchaseDate,
      price: (data['price'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'INR',
      storeName: data['storeName'] as String?,
      warrantyMonths: (data['warrantyMonths'] as num?)?.toInt() ?? 12,
      warrantyEndDate: warrantyEndDate,
      extendedWarrantyEndDate: data['extendedWarrantyEndDate'] != null
          ? DateTime.tryParse(data['extendedWarrantyEndDate'] as String)
          : null,
      isLifetime: data['isLifetime'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ?? purchaseDate,
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? purchaseDate,
    );
  }
}

final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  final service = FirebaseSyncService(ref.watch(warrantyRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});
