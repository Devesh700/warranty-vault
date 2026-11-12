import 'package:flutter/material.dart';

import '../../domain/enums.dart';

IconData categoryIconData(ItemCategory category) {
  switch (category) {
    case ItemCategory.phone:
      return Icons.smartphone_rounded;
    case ItemCategory.laptop:
      return Icons.laptop_mac_rounded;
    case ItemCategory.tv:
      return Icons.tv_rounded;
    case ItemCategory.ac:
      return Icons.ac_unit_rounded;
    case ItemCategory.fridge:
      return Icons.kitchen_rounded;
    case ItemCategory.washingMachine:
      return Icons.local_laundry_service_rounded;
    case ItemCategory.kitchenAppliance:
      return Icons.blender_rounded;
    case ItemCategory.audio:
      return Icons.headphones_rounded;
    case ItemCategory.vehicle:
      return Icons.directions_car_rounded;
    case ItemCategory.furniture:
      return Icons.chair_rounded;
    case ItemCategory.other:
      return Icons.inventory_2_rounded;
  }
}

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.category,
    this.size = 44,
  });

  final ItemCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        categoryIconData(category),
        color: colorScheme.primary,
        size: size * 0.54,
      ),
    );
  }
}
