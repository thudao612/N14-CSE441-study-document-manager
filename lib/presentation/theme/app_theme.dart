import 'package:flutter/material.dart';

/// Hệ thống Theme phong cách Cashew
/// Tối ưu thẩm mỹ với màu sắc hài hòa, góc bo cong mềm mại và bố cục phân lớp hiện đại
class AppTheme {
  // Bảng màu nhận diện chính (Cashew Palette kết hợp Xanh Mint Pastel)
  static const Color primary = Color(0xFF3F51B5);       // Indigo chính
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primaryLight = Color(0xFFE8EAF6);
  
  static const Color secondary = Color(0xFF00897B);     // Teal ngọc bích
  static const Color mintAccent = Color(0xFF10B981);    // Xanh Mint tươi
  static const Color accent = Color(0xFFF59E0B);        // Hổ phách (Amber)
  static const Color error = Color(0xFFE11D48);         // Đỏ hồng (Rose red)
  
  // Màu nền xanh mint pastel nhạt dịu mắt, làm nổi bật các thẻ trắng
  static const Color background = Color(0xFFEAF6F0);    // Xanh mint pastel
  static const Color surface = Color(0xFFFFFFFF);       // Mặt thẻ Card trắng tinh khôi
  static const Color surfaceVariant = Color(0xFFDEF2E8); // Xanh mint siêu nhạt
  
  static const Color textPrimary = Color(0xFF0F291E);   // Chữ đậm sắc nét
  static const Color textSecondary = Color(0xFF52796F); // Chữ phụ xanh rêu thanh lịch
  static const Color border = Color(0xFFCCEBD9);        // Viền mint pastel nhẹ

  /// Theme sáng (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        toolbarHeight: 72,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }
}
