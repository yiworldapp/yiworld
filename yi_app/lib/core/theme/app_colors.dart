import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color black      = Color(0xFF0A0A0A);
  static const Color surface    = Color(0xFF111111);
  static const Color surfaceAlt = Color(0xFF1A1A1A);
  static const Color card       = Color(0xFF141414);

  // Brand — primary is orange, secondary green kept for badges/success
  static const Color green      = Color(0xFFF97316); // primary action colour (orange)
  static const Color greenLight = Color(0xFFFB923C); // lighter orange
  static const Color greenMuted = Color(0xFFEA580C); // darker orange

  static const Color orange     = Color(0xFFF97316);
  static const Color orangeMuted= Color(0xFF9A3412);

  // Keep real green for success states & vertical badges
  static const Color accentGreen      = Color(0xFF16A34A);
  static const Color accentGreenLight = Color(0xFF22C55E);

  static const Color yellow     = Color(0xFFEAB308);
  static const Color yellowMuted= Color(0xFF854D0E);

  // Text
  static const Color white      = Color(0xFFFAFAFA);
  static const Color textMuted  = Color(0xFF6B7280);
  static const Color textHint   = Color(0xFF4B5563);

  // Borders / Dividers
  static const Color border     = Color(0xFF262626);
  static const Color divider    = Color(0xFF1F1F1F);

  // Status
  static const Color error      = Color(0xFFEF4444);
  static const Color success    = Color(0xFF16A34A);
  static const Color warning    = Color(0xFFF59E0B);

}
