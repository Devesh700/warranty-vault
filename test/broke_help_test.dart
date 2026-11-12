import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warranty_vault/core/claim_bundle_service.dart';
import 'package:warranty_vault/core/date_logic.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/data/repositories/warranty_repository.dart';
import 'package:warranty_vault/domain/enums.dart';
import 'package:warranty_vault/domain/models.dart';
import 'package:warranty_vault/features/broke_help/broke_help_screen.dart';
import 'package:warranty_vault/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('BrokeHelpScreen shows brand contact & status for active item',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);

    final today = dateOnly(DateTime.now());
    final item = WarrantyItem(
      id: 'active-tv',
      name: 'Samsung 55QLED TV',
      brand: 'Samsung',
      category: ItemCategory.tv,
      purchaseDate: today,
      currency: 'INR',
      warrantyMonths: 12,
      warrantyEndDate: computeWarrantyEndDate(today, 12),
      createdAt: today,
      updatedAt: today,
    );
    await repo.upsertItem(item);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BrokeHelpScreen(itemId: item.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Under warranty until'), findsOneWidget);
    expect(find.text('Samsung'), findsOneWidget);
    expect(find.textContaining('1800-407-267864'), findsOneWidget);
    expect(
      find.text('Verify contact details with the brand before calling.'),
      findsOneWidget,
    );
    expect(find.text('Share claim bundle (PDF)'), findsOneWidget);
    expect(find.text('Compare repair-protection plans'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('BrokeHelpScreen shows expired banner & sponsored offer',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);

    final oldDate = DateTime(2022, 1, 1);
    final item = WarrantyItem(
      id: 'expired-ac',
      name: 'LG Split AC',
      brand: 'LG',
      category: ItemCategory.ac,
      purchaseDate: oldDate,
      currency: 'INR',
      warrantyMonths: 12,
      warrantyEndDate: computeWarrantyEndDate(oldDate, 12),
      createdAt: oldDate,
      updatedAt: oldDate,
    );
    await repo.upsertItem(item);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BrokeHelpScreen(itemId: item.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warranty expired'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sponsored'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.text('Compare repair-protection plans'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('ClaimBundleService builds a valid PDF file', () async {
    final today = DateTime(2026, 6, 1);
    final item = WarrantyItem(
      id: 'pdf-1',
      name: 'Sony Headphones',
      brand: 'Sony',
      category: ItemCategory.audio,
      purchaseDate: today,
      price: 24990,
      currency: 'INR',
      storeName: 'Croma',
      warrantyMonths: 12,
      warrantyEndDate: computeWarrantyEndDate(today, 12),
      createdAt: today,
      updatedAt: today,
    );

    final bytes = await ClaimBundleService().buildClaimPdfBytes(
      item: item,
      attachments: const [],
    );
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
