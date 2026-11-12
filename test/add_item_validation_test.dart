import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warranty_vault/core/ocr_parser.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/features/add_item/add_item_screen.dart';
import 'package:warranty_vault/features/add_item/add_source_sheet.dart';
import 'package:warranty_vault/l10n/generated/app_localizations.dart';

Widget _wrapScreen(AppDatabase db, Widget child) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Add Item form validates empty product name and negative price',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(_wrapScreen(db, const AddItemScreen()));
    await tester.pumpAndSettle();

    // Tap Save without entering product name
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Please enter a product name'));
    expect(find.text('Please enter a product name'), findsOneWidget);

    // Enter valid product name and invalid negative price
    await tester.enterText(find.byType(TextFormField).first, 'Sony TV');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'e.g. 42999'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. 42999'),
      '-100',
    );
    await tester.pumpAndSettle();
    // Unfocus text field before scrolling to Save button
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Enter a valid positive amount'));
    expect(find.text('Enter a valid positive amount'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('OCR prefill shows auto-filled tags on Add Item form',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    final ocr = OcrParseResult(
      productName: const OcrFieldSuggestion(
        value: 'Sony WH-1000XM5',
        confidence: OcrConfidence.high,
      ),
      brand: const OcrFieldSuggestion(
        value: 'Sony',
        confidence: OcrConfidence.high,
      ),
      totalAmount: const OcrFieldSuggestion(
        value: 29990,
        confidence: OcrConfidence.low,
      ),
    );

    await tester.pumpWidget(
      _wrapScreen(
        db,
        AddItemScreen(
          launchArgs: AddItemLaunchArgs(ocrResult: ocr),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sony WH-1000XM5'), findsOneWidget);
    expect(find.text('auto-filled'), findsAtLeastNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
