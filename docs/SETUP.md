# HƯỚNG DẪN CẤU HÌNH HỆ THỐNG (SETUP GUIDE)
## Tích hợp Hybrid Cloud: Firebase Authentication + Firebase Storage + Supabase PostgreSQL

Tài liệu này hướng dẫn chi tiết từng bước tự cấu hình dịch vụ trên **Firebase Console** và **Supabase Dashboard** để ứng dụng Quản lý Tài liệu Học tập hoạt động hoàn chỉnh.

---

## PHẦN 1: CẤU HÌNH TRÊN FIREBASE CONSOLE

### 1.1. Truy cập dự án Firebase
1. Truy cập vào [Firebase Console](https://console.firebase.google.com/).
2. Chọn dự án Firebase hiện tại của nhóm: **`nhom14-mobile-app`** (hoặc dự án của bạn).

### 1.2. Kích hoạt Firebase Authentication
1. Tại menu bên trái, chọn **Build** -> **Authentication**.
2. Nhấp vào tab **Sign-in method**.
3. Bật các nhà cung cấp xác thực sau:
   - **Google**:
     - Bấm **Enable**.
     - Chọn *Project support email* là email quản trị của bạn.
     - Nhấn **Save**.
   - **Email/Password**:
     - Bấm **Enable** ở mục *Email/Password*.
     - Bỏ qua mục *Email link (passwordless sign-in)*.
     - Nhấn **Save**.
   - **Anonymous (Khách)**: Bật *Enable* để hỗ trợ chế độ trải nghiệm nhanh nếu cần.
4. *(Dành cho thiết bị Android)*: 
   - Vào **Project settings** (biểu tượng bánh răng) -> tab **General** -> mục *Your apps* -> chọn app Android `com.studymanager.study_document_manager`.
   - Bấm **Add fingerprint** và dán mã **SHA-1** máy phát triển của bạn (lấy bằng lệnh `cd android && ./gradlew signingReport`).

### 1.3. Kích hoạt Firebase Cloud Storage
1. Tại menu bên trái, chọn **Build** -> **Storage**.
2. Nhấn **Get started**:
   - Chọn chế độ bảo mật: Bắt đầu ở chế độ thử nghiệm hoặc sản xuất.
   - Chọn Cloud Storage location: `asia-southeast1` (Singapore) hoặc `asia-southeast2` để có tốc độ truy cập nhanh nhất tại Việt Nam.
   - Nhấn **Done**.
3. Cập nhật **Security Rules cho Firebase Storage**:
   - Vào tab **Rules**.
   - Sao chép toàn bộ nội dung từ tệp `storage.rules` trong thư mục gốc của dự án và dán vào:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /documents/{userId}/{allPaths=**} {
      // Cho phép đọc: Mọi người dùng đã đăng nhập Firebase Auth
      allow read: if request.auth != null;

      // Cho phép tải lên: Chỉ chính chủ userId và kích thước < 50MB
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 50 * 1024 * 1024;

      // Cho phép xóa: Duy nhất chính chủ userId
      allow delete: if request.auth != null 
                    && request.auth.uid == userId;
    }

    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write, delete: if false;
    }
  }
}
```
   - Nhấn **Publish** để áp dụng quy tắc.

---

## PHẦN 2: CẤU HÌNH TRÊN SUPABASE DASHBOARD

### 2.1. Tạo dự án Supabase
1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard).
2. Nhấn **New project**:
   - **Organization**: Chọn tổ chức của bạn.
   - **Name**: `study-document-manager`.
   - **Database Password**: Đặt mật khẩu mạnh và lưu lại.
   - **Region**: `Southeast Asia (Singapore)` để tối ưu độ trễ.
   - Nhấn **Create new project** (chờ khoảng 1-2 phút để cụm PostgreSQL khởi tạo).

### 2.2. Chạy Khởi tạo Database Schema & RLS
1. Tại thanh menu bên trái Supabase Dashboard, chọn biểu tượng **SQL Editor** (icon `>_`).
2. Nhấn **New query**.
3. Mở tệp `supabase/schema.sql` trong mã nguồn dự án, sao chép toàn bộ nội dung và dán vào ô SQL Editor.
4. Bấm nút **Run** (hoặc `Ctrl + Enter`).
5. Kết quả hiển thị `Success. No rows returned` chứng minh:
   - Đã tạo thành công 3 bảng: `users`, `documents`, `permissions`.
   - Đã tạo hàm `public.current_user_id()` để trích xuất Firebase UID.
   - Đã tạo các chỉ mục (indexes).
   - Đã kích hoạt **Row Level Security (RLS)** và áp dụng đầy đủ các Policies cho cả 3 bảng.

### 2.3. Lấy thông tin kết nối Supabase (URL & Anon Key)
1. Tại menu bên trái, chọn biểu tượng **Project Settings** (bánh răng) -> **API**.
2. Tìm mục **Project URL**: Sao chép URL có dạng `https://xxxxxxxxxxxxxxxxxxxx.supabase.co`.
3. Tìm mục **Project API keys**:
   - Sao chép khóa **`anon` `public`** (Đây là khóa công khai an toàn, được bảo vệ bằng RLS).
   - ⚠️ **CẢNH BÁO AN TOÀN:** **TUYỆT ĐỐI KHÔNG** sao chép hoặc đưa khóa `service_role` `secret` vào ứng dụng Flutter. Khóa `service_role` bỏ qua toàn bộ RLS và chỉ được dùng ở máy chủ backend bảo mật.

### 2.4. Cấu hình vào ứng dụng Flutter
Mở tệp `lib/core/config/supabase_config.dart` trong mã nguồn và cập nhật 2 hằng số:

```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_ACTUAL_PROJECT_REF.supabase.co', // Thay URL của bạn
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // Thay anon public key của bạn
  );
  ...
}
```

*Hoặc truyền qua cờ khi chạy lệnh Flutter:*
```bash
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## PHẦN 3: KIỂM TRA & XÁC NHẬN KẾT NỐI

1. Chạy lệnh cài đặt thư viện:
   ```bash
   flutter pub get
   ```
2. Kiểm tra phân tích tĩnh mã nguồn:
   ```bash
   flutter analyze
   ```
3. Chạy toàn bộ bộ kiểm thử tự động:
   ```bash
   flutter test
   ```
4. Khởi chạy ứng dụng:
   ```bash
   flutter run -d chrome     # Hoặc -d edge / thiết bị Android
   ```
5. Đăng nhập bằng Google hoặc Email/Password:
   - Mở menu góc trên bên phải màn hình chính, xác nhận:
     - Tên hiển thị người dùng.
     - Email người dùng.
     - **Mã Firebase UID** duy nhất (ví dụ: `UID: d8j2...`).
   - Vào Supabase Dashboard -> **Table Editor** -> bảng `users`: Xác nhận bản ghi của người dùng đã được tự động đồng bộ vào bảng!
