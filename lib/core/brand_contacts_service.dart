import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

class BrandContactsService {
  List<BrandContact>? _cache;

  Future<List<BrandContact>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/brand_contacts.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => BrandContact.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<BrandContact?> findForItem(WarrantyItem item) async {
    final all = await loadAll();
    final candidates = [
      if (item.brand != null) item.brand!.trim(),
      item.name.trim(),
    ];
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final lower = candidate.toLowerCase();
      for (final contact in all) {
        final bLower = contact.brand.toLowerCase();
        if (lower == bLower ||
            lower.contains(bLower) ||
            bLower.contains(lower)) {
          return contact;
        }
      }
    }
    return null;
  }
}

final brandContactsServiceProvider =
    Provider<BrandContactsService>((ref) => BrandContactsService());
