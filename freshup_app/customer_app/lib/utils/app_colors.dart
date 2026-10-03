import 'package:flutter/material.dart';

/// Central color palette for the app.
/// Fresh, organic, and appetizing grocery theme.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Botanical Forest Emerald)
  static const Color primary = Color(0xFF0D5C3A); // Deep botanical emerald
  static const Color primaryDark = Color(0xFF083D26); // Rich deep forest
  static const Color primaryLight = Color(0xFFE8F5EE); // Soft mint tint for badges & chips
  static const Color primaryMedium = Color(0xFF16794F); // Vibrant leaf green

  // Accent & Action Colors (Warm Tangerine & Sun Gold)
  static const Color accent = Color(0xFFF58220); // Warm appetizing tangerine for discounts/sale
  static const Color accentDark = Color(0xFFD66A0E);
  static const Color accentLight = Color(0xFFFFF4EB); // Soft peach background for offer tags

  // Background & Surface
  static const Color background = Color(0xFFF8F9FA); // Clean soft neutral background
  static const Color surface = Colors.white; // Pure white for cards & elevated sheets
  static const Color cardBorder = Color(0xFFE8ECE9); // Subtle organic border tint

  // Text Colors
  static const Color textPrimary = Color(0xFF19201D); // Deep charcoal slate for crisp readability
  static const Color textSecondary = Color(0xFF6B7B73); // Sage slate for subtitles and units
  static const Color textMuted = Color(0xFF9CA8A2); // Subtle placeholder text

  // Semantic Colors
  static const Color error = Color(0xFFEF4444); // Clean coral red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981); // Emerald success
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber warning

  // Dividers & Shimmer
  static const Color divider = Color(0xFFEFF2F0);
  static const Color shimmerBase = Color(0xFFE5E9E7);
  static const Color shimmerHighlight = Color(0xFFF3F6F4);
}
