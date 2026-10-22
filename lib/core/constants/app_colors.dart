import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Luxury deep olive green inspired by design reference
  static const Color primary = Color(0xFF27382B); // Deep luxury olive green
  static const Color primaryDark = Color(0xFF1B281E); // Darker forest olive
  static const Color primaryLight = Color(0xFFE8EFE9); // Soft sage cream
  static const Color primarySurface = Color(0xFFF3F6F3); // Soft olive tint

  // Category Colors
  static const Color categoryTan = Color(0xFFC29B72); // Warm caramel / camel tan (selected category)
  static const Color categoryTanLight = Color(0xFFEFE8DD); // Soft warm tan / cream (unselected category)
  static const Color categoryTextDark = Color(0xFF3C352E); // Dark charcoal brown for category text

  // Secondary & Accents
  static const Color secondary = Color(0xFFE5A83B); // Warm gold / amber
  static const Color secondaryLight = Color(0xFFFDF4E6);
  static const Color terracotta = Color(0xFFBA4B2E); // Terracotta / warm rust from reference
  static const Color terracottaLight = Color(0xFFFCEEEA); // Soft peach / terracotta tint
  static const Color freeBadge = Color(0xFFBA4B2E); // Terracotta red from reference
  static const Color freeBadgeBg = Color(0xFFFCEEEA);

  // AI & Card Accents
  static const Color aiCardBg = Color(0xFFE8F3EA); // Soft mint green from Pasang Iklan card
  static const Color aiCardDark = Color(0xFF27382B);
  static const Color aiCardBorder = Color(0xFFD6E8D9);

  // Status Colors
  static const Color statusAvailable = Color(0xFF2D6A4F); // Tersedia
  static const Color statusNegotiating = Color(0xFFD48B38); // Dalam Kesepakatan
  static const Color statusCompleted = Color(0xFF707770); // Selesai / Terjual

  // Neutral Colors (Light mode) - Warm cream luxury palette
  static const Color background = Color(0xFFFAF7F2); // Warm off-white / light cream matching reference
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1EFEA); // Soft warm pill / chip background
  static const Color textPrimary = Color(0xFF1A1D1A); // Deep charcoal
  static const Color textSecondary = Color(0xFF6E746E); // Muted warm gray
  static const Color textTertiary = Color(0xFF9EA39E); // Subtle gray
  static const Color border = Color(0xFFEAE7E1); // Soft warm border
  static const Color divider = Color(0xFFEEEBE4);

  // Semantic
  static const Color error = Color(0xFFD9453B);
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFE5A83B);
  static const Color info = Color(0xFF386641);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF141915);
  static const Color darkSurface = Color(0xFF1E2420);
  static const Color darkCard = Color(0xFF1E2420);
  static const Color darkBorder = Color(0xFF2E3630);
  static const Color darkTextPrimary = Color(0xFFF8F6F2);
  static const Color darkTextSecondary = Color(0xFFA3A8A3);
}
