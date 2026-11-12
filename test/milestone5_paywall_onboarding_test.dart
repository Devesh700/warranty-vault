import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warranty_vault/core/date_logic.dart';
import 'package:warranty_vault/core/export_service.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/data/repositories/warranty_repository.dart';
import 'package:warranty_vault/domain/enums.dart';
import 'package:warranty_vault/domain/models.dart';
import 'package:warranty_vault/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('First launch shows 3-screen onboarding and leads to empty Home',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const WarrantyVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Never lose a bill again'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Get reminded before warranty ends'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Ready when something breaks'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(
      find.text('No items yet. Add your first bill in 20 seconds.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('Paywall gates 6th item and lapsed Pro keeps existing items',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);
    await repo.updateSetting('onboardingDone', 'true');

    final today = dateOnly(DateTime.now());
    // Seed 5 items (at free limit)
    for (int i = 1; i <= 5; i++) {
      await repo.upsertItem(
        WarrantyItem(
          id: 'free-$i',
          name: 'Device $i',
          category: ItemCategory.phone,
          purchaseDate: today,
          currency: 'INR',
          warrantyMonths: 12,
          warrantyEndDate: computeWarrantyEndDate(today, 12),
          createdAt: today,
          updatedAt: today,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const WarrantyVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tapping Add FAB on 6th item opens Paywall
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Keep every bill safe, forever'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);

    // Dismiss paywall
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Seed a 6th item (simulating lapsed Pro subscription): existing items remain visible
    await repo.upsertItem(
      WarrantyItem(
        id: 'pro-6',
        name: 'Device 6',
        category: ItemCategory.laptop,
        purchaseDate: today,
        currency: 'INR',
        warrantyMonths: 12,
        warrantyEndDate: computeWarrantyEndDate(today, 12),
        createdAt: today,
        updatedAt: today,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('6 items, 0 expiring soon'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('Font scale 1.3x renders Home, Settings, and Paywall without overflow',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);
    await repo.updateSetting('onboardingDone', 'true');

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const WarrantyVaultApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Upgrade to Pro'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Upgrade to Pro'));
    await tester.pumpAndSettle();

    expect(find.text('Keep every bill safe, forever'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('ExportService builds valid ZIP archive with items.csv', () async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);

    final today = DateTime(2026, 5, 1);
    await repo.upsertItem(
      WarrantyItem(
        id: 'exp-1',
        name: 'Apple MacBook, Pro',
        brand: 'Apple',
        category: ItemCategory.laptop,
        purchaseDate: today,
        price: 149900,
        currency: 'INR',
        warrantyMonths: 12,
        warrantyEndDate: computeWarrantyEndDate(today, 12),
        createdAt: today,
        updatedAt: today,
      ),
    );

    final bytes = await ExportService(repo).buildExportZipBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final csvFile = archive.findFile('items.csv');
    expect(csvFile, isNotNull);

    final csvContent = utf8.decode(csvFile!.content as List<int>);
    expect(csvContent, contains('"Apple MacBook, Pro"'));
    expect(csvContent, contains('Apple'));
  });
}
