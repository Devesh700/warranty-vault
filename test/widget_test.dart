import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Milestone 1: App shell renders tabs, theme and EN/HI switch',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    await db.into(db.appSettings).insert(
          const AppSettingsCompanion(
            key: Value('onboardingDone'),
            value: Value('true'),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const WarrantyVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Bottom tabs visible in English
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Expiring'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Switch to Dark theme
    await tester.scrollUntilVisible(
      find.text('Dark'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Ensure Hindi option is visible and tap it
    await tester.scrollUntilVisible(
      find.text('हिन्दी (Hindi)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('हिन्दी (Hindi)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी (Hindi)'));
    await tester.pumpAndSettle();

    expect(find.text('सामान'), findsOneWidget);
    expect(find.text('जल्द समाप्त'), findsOneWidget);
    expect(find.text('सेटिंग्स'), findsAtLeastNWidgets(1));

    // Verify Dark ThemeMode applied
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    // Unmount widget tree before DB teardown
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
