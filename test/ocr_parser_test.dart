import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/ocr_parser.dart';
import 'package:warranty_vault/domain/enums.dart';

void main() {
  final referenceNow = DateTime(2026, 11, 11);

  final sampleBills = <({
    String label,
    String text,
    DateTime expectedDate,
    double expectedTotal,
    String? expectedBrand,
  })>[
    (
      label: 'Croma AC bill (dd/mm/yyyy)',
      text: '''
TAX INVOICE
CROMA RETAIL STORE
Date: 15/05/2026
1 LG Split AC 1.5T Inverter LS-Q18YNXA 42,999.00
Grand Total: Rs. 42,999.00
Thank you for shopping!
''',
      expectedDate: DateTime(2026, 5, 15),
      expectedTotal: 42999.0,
      expectedBrand: 'LG',
    ),
    (
      label: 'Amazon India laptop invoice (dd-mm-yyyy)',
      text: '''
Amazon Seller Services Pvt Ltd
Invoice Date: 03-08-2025
Apple MacBook Air M3 13-inch
Total Amount: INR 1,14,900.00
''',
      expectedDate: DateTime(2025, 8, 3),
      expectedTotal: 114900.0,
      expectedBrand: 'Apple',
    ),
    (
      label: 'Reliance Digital TV bill (dd MMM yyyy)',
      text: '''
Reliance Digital
Bill Date: 12 Aug 2025
Samsung 55QLED Smart TV QA55Q60D 64,990.00
Net Payable: ₹ 64,990.00
''',
      expectedDate: DateTime(2025, 8, 12),
      expectedTotal: 64990.0,
      expectedBrand: 'Samsung',
    ),
    (
      label: 'Vijay Sales Washing Machine',
      text: '''
VIJAY SALES
Dated: 20/01/2026
Bosch 7kg Front Load Washing Machine WAJ2416SIN
Invoice Total 31500.00
''',
      expectedDate: DateTime(2026, 1, 20),
      expectedTotal: 31500.0,
      expectedBrand: 'Bosch',
    ),
    (
      label: 'Flipkart Phone invoice',
      text: '''
Flipkart Retail
Order Date: 09-10-2025
OnePlus 13R 5G Smartphone CPH2691
Amount Payable: Rs 39999
''',
      expectedDate: DateTime(2025, 10, 9),
      expectedTotal: 39999.0,
      expectedBrand: 'OnePlus',
    ),
    (
      label: 'Sony Audio store receipt',
      text: '''
SONY CENTER MUMBAI
Date: 14 Sep 2025
Sony WH-1000XM5 Wireless Headphones
Subtotal: 24990.00
Grand Total: 29488.20
''',
      expectedDate: DateTime(2025, 9, 14),
      expectedTotal: 29488.20,
      expectedBrand: 'Sony',
    ),
    (
      label: 'Whirlpool Fridge dealer bill',
      text: '''
KUMAR APPLIANCES
25/02/2026
Whirlpool 265L Double Door Refrigerator IFPRO278
Total: ₹ 26,450.00
''',
      expectedDate: DateTime(2026, 2, 25),
      expectedTotal: 26450.0,
      expectedBrand: 'Whirlpool',
    ),
    (
      label: 'Philips Kitchen appliance',
      text: '''
MODERN ELECTRONICS
Invoice Date: 18/06/2026
Philips Air Fryer HD9252/90
Bill Amount: Rs. 8,495.00
''',
      expectedDate: DateTime(2026, 6, 18),
      expectedTotal: 8495.0,
      expectedBrand: 'Philips',
    ),
    (
      label: 'Dell Laptop bill with multi-line total',
      text: '''
DELL EXCLUSIVE STORE
Date: 01-03-2026
Dell Inspiron 15 Laptop 3530
Grand Total
Rs. 58,990.00
''',
      expectedDate: DateTime(2026, 3, 1),
      expectedTotal: 58990.0,
      expectedBrand: 'Dell',
    ),
    (
      label: 'Honda Vehicle accessory / scooter receipt',
      text: '''
APEX HONDA MOTORS
04 Apr 2026
Honda Activa 6G Scooter
Net Amount: INR 82,400.00
''',
      expectedDate: DateTime(2026, 4, 4),
      expectedTotal: 82400.0,
      expectedBrand: 'Honda',
    ),
  ];

  group('OcrParser on 10 sample bills', () {
    test('extracts date on >= 7 and total on >= 6 of 10 bills', () {
      int dateMatches = 0;
      int totalMatches = 0;
      int brandMatches = 0;

      for (final bill in sampleBills) {
        final res = OcrParser.parse(bill.text, now: referenceNow);
        if (res.purchaseDate?.value == bill.expectedDate) {
          dateMatches++;
        }
        if (res.totalAmount?.value == bill.expectedTotal) {
          totalMatches++;
        }
        if (res.brand?.value == bill.expectedBrand) {
          brandMatches++;
        }
      }

      expect(dateMatches, greaterThanOrEqualTo(7));
      expect(totalMatches, greaterThanOrEqualTo(6));
      expect(brandMatches, greaterThanOrEqualTo(7));
    });

    test('extracts store name, product line, and category inference', () {
      final res = OcrParser.parse(sampleBills.first.text, now: referenceNow);
      expect(res.storeName?.value, 'CROMA RETAIL STORE');
      expect(res.productName?.value, contains('LG Split AC'));
      expect(res.category?.value, ItemCategory.ac);
      expect(res.purchaseDate?.confidence, OcrConfidence.high);
      expect(res.totalAmount?.confidence, OcrConfidence.high);
    });
  });

  group('OcrParser edge cases (blurry, empty, future date)', () {
    test('does not crash on empty or whitespace text', () {
      expect(OcrParser.parse('').isEmpty, isTrue);
      expect(OcrParser.parse('   \n\n  ').isEmpty, isTrue);
    });

    test('does not crash on blurry/gibberish OCR noise', () {
      final res = OcrParser.parse(
        '%%% 123 ###\n.. ?? --\n99/99/9999\nx',
        now: referenceNow,
      );
      expect(res.purchaseDate, isNull);
    });

    test('ignores future dates on invoice', () {
      final res = OcrParser.parse(
        'Date: 25/12/2099\nTotal: Rs. 500.00',
        now: referenceNow,
      );
      expect(res.purchaseDate, isNull);
      expect(res.totalAmount?.value, 500.0);
    });
  });
}
