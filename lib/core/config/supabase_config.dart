import 'package:flutter/foundation.dart';

/// Cấu hình kết nối Supabase Cloud (PostgreSQL Database & Row Level Security)
/// Lưu ý bảo mật:
/// - TUYỆT ĐỐI KHÔNG đưa `service_role` key vào mã nguồn Flutter client.
/// - Chỉ sử dụng `anonKey` (Public Anonymous Key) kết hợp với Row Level Security (RLS).
/// - Định danh người dùng được xác thực thông qua Firebase Authentication JWT Token.
class SupabaseConfig {
  /// Supabase Project URL (ví dụ: https://your-project-id.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cqjuubzutyricjokufiq.supabase.co',
  );

  /// Supabase Public Anon Key (Khóa công khai an toàn cho Client)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_3EgC8MMhsZPRRa0TgJsYGA_CmuOcfNF', 
  );

  /// Supabase Storage Bucket cho tài liệu học tập
  static const String storageBucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'documents',
  );

  /// Kiểm tra cấu hình Supabase đã hợp lệ hay chưa
  static bool get isConfigured {
    final isUrlValid = supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('your-project-id');
    final isKeyValid = supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('dummy_anon_key');
    return isUrlValid && isKeyValid;
  }

  /// In thông tin chẩn đoán cấu hình
  static void printStatus() {
    debugPrint('--- [SUPABASE CONFIG STATUS] ---');
    debugPrint('Supabase URL: $supabaseUrl');
    debugPrint('Anon Key Configured: ${supabaseAnonKey.isNotEmpty ? 'YES' : 'NO'}');
    debugPrint('Is Fully Configured: $isConfigured');
    debugPrint('--------------------------------');
  }
}
