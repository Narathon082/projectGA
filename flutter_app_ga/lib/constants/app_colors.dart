import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = false;
  static Color get bg         => isDark ? const Color(0xFF121212) : const Color(0xFFEEEEFF);
  static Color get surface    => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get cardBorder => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0F0);
  static Color get primary    => isDark ? const Color(0xFF8C88FF) : const Color(0xFF4040C0);
  static Color get primaryBg  => isDark ? const Color(0xFF2C2C3C) : const Color(0xFFEEEEFF);
  static Color get textDark   => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A50);
  static Color get textMuted  => isDark ? const Color(0xFF888888) : const Color(0xFF9090B0);
  static Color get textSub    => isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6060A0);
  static Color get badgeBg    => isDark ? const Color(0xFF33334D) : const Color(0xFFE8E4FF);
  static Color get badgeText  => isDark ? const Color(0xFF8C88FF) : const Color(0xFF5050B0);
  static Color get divider    => isDark ? const Color(0xFF333333) : const Color(0xFFE8E8F5);
}
