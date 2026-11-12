import '../domain/enums.dart';

enum OcrConfidence { high, low }

class OcrFieldSuggestion<T> {
  const OcrFieldSuggestion({
    required this.value,
    required this.confidence,
  });

  final T value;
  final OcrConfidence confidence;

  bool get isLowConfidence => confidence == OcrConfidence.low;
}

class OcrParseResult {
  const OcrParseResult({
    this.purchaseDate,
    this.totalAmount,
    this.storeName,
    this.productName,
    this.brand,
    this.category,
  });

  final OcrFieldSuggestion<DateTime>? purchaseDate;
  final OcrFieldSuggestion<double>? totalAmount;
  final OcrFieldSuggestion<String>? storeName;
  final OcrFieldSuggestion<String>? productName;
  final OcrFieldSuggestion<String>? brand;
  final OcrFieldSuggestion<ItemCategory>? category;

  int get fieldsFilledCount {
    int count = 0;
    if (purchaseDate != null) count++;
    if (totalAmount != null) count++;
    if (storeName != null) count++;
    if (productName != null) count++;
    if (brand != null) count++;
    return count;
  }

  bool get isEmpty => fieldsFilledCount == 0;
}

class OcrParser {
  OcrParser._();

  static const List<String> _knownBrands = [
    'Apple',
    'Samsung',
    'LG',
    'Sony',
    'Whirlpool',
    'Bosch',
    'IFB',
    'Voltas',
    'Daikin',
    'Blue Star',
    'Godrej',
    'Haier',
    'Panasonic',
    'Philips',
    'OnePlus',
    'Xiaomi',
    'Redmi',
    'Realme',
    'Vivo',
    'Oppo',
    'Google',
    'Motorola',
    'Nothing',
    'Dell',
    'HP',
    'Lenovo',
    'Asus',
    'Acer',
    'MSI',
    'JBL',
    'Bose',
    'boAt',
    'Sennheiser',
    'Dyson',
    'Prestige',
    'Bajaj',
    'Havells',
    'Crompton',
    'Honda',
    'Hero',
    'TVS',
    'Bajaj Auto',
    'Royal Enfield',
    'Maruti',
    'Hyundai',
    'Tata',
    'IKEA',
  ];

  static const Map<String, int> _monthMap = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  static final RegExp _numericDateRegex = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b',
  );
  static final RegExp _isoDateRegex = RegExp(
    r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b',
  );
  static final RegExp _namedDateRegex = RegExp(
    r'\b(\d{1,2})[\s\-\/]([A-Za-z]{3,9})[\s\-\/,]+(\d{2,4})\b',
  );

  static final RegExp _dateHintRegex = RegExp(
    r'\b(date|dated|invoice\s*date|bill\s*date|purchase\s*date|dt)\b',
    caseSensitive: false,
  );

  static final RegExp _totalHintRegex = RegExp(
    r'\b(grand\s*total|net\s*(?:amount|payable|total)|total\s*(?:amount|payable|bill|value|due)?|amount\s*(?:payable|due)|invoice\s*total|bill\s*amount)\b',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'(?:(?:rs\.?|inr|₹|\$|€|£)\s*)?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _modelPatternRegex = RegExp(
    r'\b(?=[A-Z0-9\-]{4,18}\b)(?=.*[A-Z])(?=.*\d)[A-Z0-9\-]+\b',
  );

  static final RegExp _headerSkipRegex = RegExp(
    r'^(tax\s*invoice|retail\s*invoice|invoice|bill\s*of\s*supply|cash\s*memo|receipt|original|duplicate|customer\s*copy|gstin|gst\s*no|cin|pan|ph|phone|tel|mob|email|www\.|http|\d+$)',
    caseSensitive: false,
  );

  static OcrParseResult parse(String rawText, {DateTime? now}) {
    if (rawText.trim().isEmpty) {
      return const OcrParseResult();
    }

    final referenceNow = now ?? DateTime.now();
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const OcrParseResult();
    }

    final purchaseDate = _extractDate(lines, referenceNow);
    final totalAmount = _extractTotal(lines);
    final storeName = _extractStoreName(lines);
    final productAndBrand = _extractProductAndBrand(lines);

    return OcrParseResult(
      purchaseDate: purchaseDate,
      totalAmount: totalAmount,
      storeName: storeName,
      productName: productAndBrand.$1,
      brand: productAndBrand.$2,
      category: productAndBrand.$3,
    );
  }

  static OcrFieldSuggestion<DateTime>? _extractDate(
    List<String> lines,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    OcrFieldSuggestion<DateTime>? fallback;

    for (final line in lines) {
      final hasHint = _dateHintRegex.hasMatch(line);
      final parsed = _parseDateInLine(line, today);
      if (parsed == null) continue;

      if (hasHint) {
        return OcrFieldSuggestion(
          value: parsed,
          confidence: OcrConfidence.high,
        );
      }
      fallback ??= OcrFieldSuggestion(
        value: parsed,
        confidence: OcrConfidence.low,
      );
    }

    return fallback;
  }

  static DateTime? _parseDateInLine(String line, DateTime today) {
    final named = _namedDateRegex.firstMatch(line);
    if (named != null) {
      final day = int.tryParse(named.group(1)!);
      final month = _monthMap[named.group(2)!.toLowerCase()];
      final year = _normalizeYear(int.tryParse(named.group(3)!));
      final dt = _validateDate(year, month, day, today);
      if (dt != null) return dt;
    }

    final iso = _isoDateRegex.firstMatch(line);
    if (iso != null) {
      final year = int.tryParse(iso.group(1)!);
      final month = int.tryParse(iso.group(2)!);
      final day = int.tryParse(iso.group(3)!);
      final dt = _validateDate(year, month, day, today);
      if (dt != null) return dt;
    }

    final numMatch = _numericDateRegex.firstMatch(line);
    if (numMatch != null) {
      final d = int.tryParse(numMatch.group(1)!);
      final m = int.tryParse(numMatch.group(2)!);
      final y = _normalizeYear(int.tryParse(numMatch.group(3)!));
      final dt = _validateDate(y, m, d, today);
      if (dt != null) return dt;
    }
    return null;
  }

  static int? _normalizeYear(int? y) {
    if (y == null) return null;
    if (y < 100) return 2000 + y;
    return y;
  }

  static DateTime? _validateDate(
    int? year,
    int? month,
    int? day,
    DateTime today,
  ) {
    if (year == null || month == null || day == null) return null;
    if (year < 1995 || year > today.year) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    if (dt.isAfter(today)) return null;
    return dt;
  }

  static OcrFieldSuggestion<double>? _extractTotal(List<String> lines) {
    final candidates = <({double value, bool hinted, int priority})>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('gstin') ||
          lower.contains('phone') ||
          lower.contains('mobile') ||
          lower.contains('pin') ||
          lower.contains('hsn') ||
          lower.contains('serial') ||
          lower.contains('imei')) {
        continue;
      }

      final isTotalLine = _totalHintRegex.hasMatch(line);
      final isGrand = lower.contains('grand total') ||
          lower.contains('net payable') ||
          lower.contains('amount payable');
      final isSubtotal = lower.contains('sub total') || lower.contains('subtotal');

      // Also check next line if total keyword is on a line with no number
      final targetLine = (isTotalLine && !_amountRegex.hasMatch(line) && i + 1 < lines.length)
          ? '${lines[i]} ${lines[i + 1]}'
          : line;

      final hasCurrencyMarker = RegExp(r'(rs\.?|inr|₹|\$|€|£)', caseSensitive: false)
          .hasMatch(targetLine);

      for (final match in _amountRegex.allMatches(targetLine)) {
        final rawNum = match.group(1)?.replaceAll(',', '');
        if (rawNum == null) continue;
        // Skip likely dates/phone numbers/zip codes if unhinted
        if (!isTotalLine && !hasCurrencyMarker && !rawNum.contains('.')) {
          continue;
        }
        final val = double.tryParse(rawNum);
        if (val == null || val <= 0 || val > 50000000) continue;

        final priority = isGrand
            ? 3
            : (isTotalLine && !isSubtotal)
                ? 2
                : isTotalLine
                    ? 1
                    : 0;
        candidates.add((
          value: val,
          hinted: isTotalLine && !isSubtotal,
          priority: priority,
        ));
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.value.compareTo(a.value);
    });

    final best = candidates.first;
    return OcrFieldSuggestion(
      value: best.value,
      confidence: best.hinted ? OcrConfidence.high : OcrConfidence.low,
    );
  }

  static OcrFieldSuggestion<String>? _extractStoreName(List<String> lines) {
    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i];
      if (line.length < 3 || line.length > 60) continue;
      if (_headerSkipRegex.hasMatch(line)) continue;
      if (!RegExp(r'[A-Za-z]{3,}').hasMatch(line)) continue;
      // Avoid lines that are mostly address/road/pin
      if (RegExp(r'\b(road|street|floor|plot|sector|marg|nagar|pin\s*code)\b',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }
      return OcrFieldSuggestion(
        value: line,
        confidence: i <= 2 ? OcrConfidence.high : OcrConfidence.low,
      );
    }
    return null;
  }

  static (
    OcrFieldSuggestion<String>?,
    OcrFieldSuggestion<String>?,
    OcrFieldSuggestion<ItemCategory>?,
  ) _extractProductAndBrand(List<String> lines) {
    String? bestLine;
    String? matchedBrand;
    int bestScore = -1;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (line.length < 4) continue;
      if (_headerSkipRegex.hasMatch(line) && !lower.contains('iphone')) {
        continue;
      }
      if (lower.contains('gstin') ||
          lower.contains('thank you') ||
          lower.contains('terms & conditions') ||
          lower.contains('authorized signatory') ||
          _totalHintRegex.hasMatch(line)) {
        continue;
      }

      String? lineBrand;
      for (final b in _knownBrands) {
        if (RegExp('\\b${RegExp.escape(b)}\\b', caseSensitive: false)
            .hasMatch(line)) {
          lineBrand = b;
          break;
        }
      }

      final hasModel = _modelPatternRegex.hasMatch(line);
      if (lineBrand != null || hasModel) {
        final score = (lineBrand != null ? 100 : 0) +
            (hasModel ? 40 : 0) +
            line.length.clamp(0, 80);
        if (score > bestScore) {
          bestScore = score;
          bestLine = _cleanProductLine(line);
          matchedBrand = lineBrand;
        }
      }
    }

    if (bestLine == null) {
      return (null, null, null);
    }

    final inferredCategory = _inferCategory(bestLine, matchedBrand);
    return (
      OcrFieldSuggestion(
        value: bestLine,
        confidence:
            matchedBrand != null ? OcrConfidence.high : OcrConfidence.low,
      ),
      matchedBrand != null
          ? OcrFieldSuggestion(
              value: matchedBrand,
              confidence: OcrConfidence.high,
            )
          : null,
      inferredCategory != null
          ? OcrFieldSuggestion(
              value: inferredCategory,
              confidence: OcrConfidence.low,
            )
          : null,
    );
  }

  static String _cleanProductLine(String line) {
    // Strip trailing prices / quantities like "1  42,999.00"
    var cleaned = line
        .replaceAll(
          RegExp(r'\s+(?:rs\.?|inr|₹)?\s*\d{1,3}(?:,\d{2,3})*\.\d{2}\s*$',
              caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'^\d+\s+'), '')
        .trim();
    if (cleaned.length > 72) {
      cleaned = cleaned.substring(0, 72).trim();
    }
    return cleaned.isEmpty ? line : cleaned;
  }

  static ItemCategory? _inferCategory(String line, String? brand) {
    final text = '${brand ?? ''} $line'.toLowerCase();
    if (RegExp(r'\b(iphone|galaxy\s*s|pixel|oneplus|redmi|realme|phone|5g\s*mobile|smartphone)\b')
        .hasMatch(text)) {
      return ItemCategory.phone;
    }
    if (RegExp(r'\b(macbook|laptop|thinkpad|ideapad|pavilion|inspiron|vivobook|zenbook)\b')
        .hasMatch(text)) {
      return ItemCategory.laptop;
    }
    if (RegExp(r'\b(tv|qled|oled|bravia|smart\s*led|television)\b')
        .hasMatch(text)) {
      return ItemCategory.tv;
    }
    if (RegExp(r'\b(ac|air\s*conditioner|split\s*ac|inverter\s*ac|ton)\b')
        .hasMatch(text)) {
      return ItemCategory.ac;
    }
    if (RegExp(r'\b(fridge|refrigerator|frost\s*free|double\s*door)\b')
        .hasMatch(text)) {
      return ItemCategory.fridge;
    }
    if (RegExp(r'\b(washing\s*machine|washer|front\s*load|top\s*load)\b')
        .hasMatch(text)) {
      return ItemCategory.washingMachine;
    }
    if (RegExp(r'\b(mixer|grinder|microwave|air\s*fryer|kettle|cooker|oven|toaster)\b')
        .hasMatch(text)) {
      return ItemCategory.kitchenAppliance;
    }
    if (RegExp(r'\b(headphone|earbuds|airpods|soundbar|speaker|wh-1000)\b')
        .hasMatch(text)) {
      return ItemCategory.audio;
    }
    if (RegExp(r'\b(scooter|bike|motorcycle|car|activa|bullet|vehicle)\b')
        .hasMatch(text)) {
      return ItemCategory.vehicle;
    }
    if (RegExp(r'\b(sofa|chair|table|bed|mattress|wardrobe|desk)\b')
        .hasMatch(text)) {
      return ItemCategory.furniture;
    }
    return null;
  }
}
