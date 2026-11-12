import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warranty_vault/core/date_logic.dart';
import 'package:warranty_vault/core/subscription_service.dart';
import 'package:warranty_vault/core/widgets/item_card.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/data/repositories/warranty_repository.dart';
import 'package:warranty_vault/domain/enums.dart';
import 'package:warranty_vault/domain/models.dart';
import 'package:warranty_vault/features/add_item/add_item_screen.dart';
import 'package:warranty_vault/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'Milestone 2: Add 10 items, verify statuses, search/filter, edit, delete with undo',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);
    await repo.updateSetting('onboardingDone', 'true');

    final today = dateOnly(DateTime.now());
    // Seed 9 items via repository + 1 via manual Add Item form (total 10)
    for (int i = 1; i <= 9; i++) {
      final DateTime purchaseDate;
      final int months;
      if (i <= 3) {
        // Active (> 30 days left)
        purchaseDate = today;
        months = 12;
      } else if (i <= 6) {
        // Expiring soon (within 15 days)
        purchaseDate = DateTime(today.year - 1, today.month, today.day)
            .add(const Duration(days: 15));
        months = 12;
      } else {
        // Expired
        purchaseDate = DateTime(today.year - 2, today.month, today.day);
        months = 12;
      }

      await repo.upsertItem(
        WarrantyItem(
          id: 'item-$i',
          name: 'Product $i',
          brand: i == 1 ? 'Apple' : 'Samsung',
          category: i == 1 ? ItemCategory.phone : ItemCategory.tv,
          purchaseDate: purchaseDate,
          currency: 'INR',
          warrantyMonths: months,
          warrantyEndDate: computeWarrantyEndDate(purchaseDate, months),
          createdAt: today,
          updatedAt: today,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          isProProvider.overrideWithValue(true),
        ],
        child: const WarrantyVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Add 10th item manually via FAB -> Enter manually
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'LG Split AC',
    );
    await tester.pumpAndSettle();

    Finder formScrollable() => find
        .descendant(
          of: find.byType(AddItemScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: formScrollable(),
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Item saved!'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Summary shows 10 items, 3 expiring soon
    expect(find.text('10 items, 3 expiring soon'), findsOneWidget);

    // Filter by Expired
    await tester.tap(find.text('Expired').first);
    await tester.pumpAndSettle();
    expect(find.text('Product 7'), findsOneWidget);
    expect(find.text('LG Split AC'), findsNothing);

    // Clear filters back to All
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();

    // Search for LG Split AC
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'LG Split AC');
    await tester.pumpAndSettle();
    final acCardFinder = find.descendant(
      of: find.byType(ItemCard),
      matching: find.text('LG Split AC'),
    );
    expect(acCardFinder, findsOneWidget);

    // Open detail & edit
    await tester.tap(acCardFinder);
    await tester.pumpAndSettle();
    expect(find.text('Something broke?'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Switch to 0m (No warranty) and save
    await tester.scrollUntilVisible(
      find.text('0m'),
      200,
      scrollable: formScrollable(),
    );
    await tester.ensureVisible(find.text('0m'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0m'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: formScrollable(),
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('No warranty'), findsAtLeastNWidgets(1));

    // Back to list and delete with Undo
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.drag(acCardFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(acCardFinder, findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
