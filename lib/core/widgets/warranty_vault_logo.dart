import 'package:flutter/material.dart';

/// Branded WarrantyVault squircle emblem with optional wordmark lockup.
class WarrantyVaultLogo extends StatelessWidget {
  const WarrantyVaultLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.subtitle,
  });

  final double size;
  final bool showWordmark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = size * 0.24;

    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F6FEB).withValues(alpha: 0.22),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/warranty_vault_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F6FEB), Color(0xFF0B3D91)],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_user_rounded,
              size: size * 0.54,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    if (!showWordmark) return emblem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(height: 14),
        Text(
          'WarrantyVault',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}
