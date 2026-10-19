# BẢNG ĐÁNH GIÁ 5 CHECKLIST NHIỆM VỤ (CHECKLIST COMPLIANCE)
## Dự án: Quản lý Tài liệu Học tập (Firebase Authentication + Firebase Storage + Supabase)

---

## TỔNG KẾT TÌNH TRẠNG THỰC HIỆN

| Checklist | Nội dung nhiệm vụ | Trạng thái | Bằng chứng mã nguồn / Kiểm thử |
| :---: | :--- | :---: | :--- |
| **Checklist 1** | **Kiểm tra dự án hiện tại:** Đọc mã nguồn, giữ nguyên cấu hình Firebase đã hoạt động, không tạo dự án mới | **HOÀN THÀNH (100%)** | • `lib/firebase_options.dart` được giữ nguyên vẹn.<br>• Clean Architecture 4 tầng (Domain, Data, UseCases, Presentation) được kế thừa và mở rộng sạch sẽ.<br>• Toàn bộ 30 bài test ban đầu tiếp tục vượt qua 100%. |
| **Checklist 2** | **Firebase Authentication:** Đăng nhập Google, đăng xuất và nhận diện người dùng bằng Firebase UID | **HOÀN THÀNH (100%)** | • `lib/presentation/screens/auth_sign_in_screen.dart`: Hỗ trợ Google Sign-In (`GoogleAuthProvider`), Email/Password và Anonymous.<br>• `lib/presentation/screens/document_home_screen.dart`: Hiển thị Email và định danh người dùng bằng `UID: ${user.uid}`, nút Đăng xuất.<br>• Tự động đồng bộ hồ sơ đăng nhập vào bảng `users` trên Supabase. |
| **Checklist 3** | **Firebase Storage + Supabase:** Lưu tệp trên Firebase Storage; tạo 3 bảng `users`, `documents`, `permissions` trên Supabase | **HOÀN THÀNH (100%)** | • `lib/data/repositories/firebase_document_storage_repository.dart`: Sử dụng SDK `firebase_storage` tải tệp lên đường dẫn `documents/{userId}/{timestamp}_{fileName}`.<br>• `storage.rules`: Khai báo quy tắc bảo mật Storage.<br>• `supabase/schema.sql`: Script DDL tạo đầy đủ 3 bảng `users`, `documents`, `permissions` với khóa ngoại, ràng buộc và indexes.<br>• DTO Models: `DocumentModel`, `DocumentPermissionModel`, `AppUserModel`. |
| **Checklist 4** | **Chức năng ứng dụng:** Tải tệp lên, danh sách, tìm kiếm, cập nhật metadata, chia sẻ qua email (viewer/editor), thu hồi quyền | **HOÀN THÀNH (100%)** | • `DocumentFormModal`: Tải tệp từ thiết bị lên Firebase Storage và tự động điền URL.<br>• `DocumentFilterBar`: Bộ lọc nhanh "Tất cả", "Của tôi", "Được chia sẻ", "Yêu thích", phân loại.<br>• `DocumentCard`: Huy hiệu vai trò `👑 Chủ sở hữu`, `✏️ Biên tập`, `👁️ Chỉ xem`.<br>• `ShareDocumentDialog`: Chia sẻ theo email với quyền `viewer`/`editor` và nút thu hồi quyền.<br>• `DocumentDetailModal`: Hiển thị quyền và điều chỉnh nút hành động tương ứng. |
| **Checklist 5** | **Bảo mật & Kiểm thử RLS:** Bật RLS 3 bảng, xác thực Firebase JWT, Storage rules, không dùng service_role, test 3 tài khoản | **HOÀN THÀNH (100%)** | • `supabase/schema.sql`: Hàm `current_user_id()`, RLS Policies chặt chẽ trên cả 3 bảng.<br>• `lib/core/config/supabase_config.dart`: Chỉ dùng Public `anonKey`, **tuyệt đối không đưa service_role key vào Flutter**.<br>• Chặn sửa đối với Viewer; chặn xóa đối với Editor & Viewer.<br>• `test/usecases/document_permission_usecase_test.dart`: Kiểm thử toàn diện 3 tài khoản A, B, C; 38/38 tests passed. |

---

## CHI TIẾT BẰNG CHỨNG TRIỂN KHAI TỪNG CHECKLIST

### 1. CHECKLIST 1: KIỂM TRA DỰ ÁN & KẾ THỪA MÃ NGUỒN
- **Đọc và phân tích:** Đọc toàn bộ các tệp cấu hình `pubspec.yaml`, `firebase_options.dart`, `firebase.json`, `main.dart`, các tầng Domain, Data, UseCases, Presentation.
- **Bảo tồn cấu trúc:** Không tạo dự án Flutter mới; mở rộng trực tiếp trên dự án `study-document-manager`.
- **Giữ nguyên chức năng Firebase Firestore:** `FirestoreDocumentRepository` và `DocumentRepositoryImpl` vẫn sẵn sàng làm nguồn dự phòng linh hoạt (fallback).

### 2. CHECKLIST 2: FIREBASE AUTHENTICATION & ĐỊNH DANH FIREBASE UID
- **Đăng nhập Google:** Gọi `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` trên Web và `signInWithProvider` trên Mobile.
- **Đăng xuất:** Nút Đăng xuất tại `PopupMenuButton` gọi `FirebaseAuth.instance.signOut()`.
- **Nhận diện người dùng bằng Firebase UID:**
  - Header màn hình chính và thông tin tài khoản hiển thị: `UID: ${user.uid}`.
  - Mọi thao tác thêm tài liệu gán `userId = currentUser.uid`.
  - Khóa chính `id` của bảng `users` trên Supabase sử dụng trực tiếp Firebase UID.

### 3. CHECKLIST 3: FIREBASE STORAGE & SUPABASE 3 BẢNG
- **Firebase Storage:**
  - Tải tệp nhị phân thông qua `FirebaseDocumentStorageRepository` sử dụng `FirebaseStorage.instance.ref()`.
  - Thiết lập ContentType tự động (PDF, Word, TXT) và Metadata (`uploadedBy`, `originalName`).
- **Supabase PostgreSQL Schema (`supabase/schema.sql`):**
  - Bảng `users`: `id` (Firebase UID PK), `email`, `display_name`, `photo_url`, `created_at`, `updated_at`.
  - Bảng `documents`: `id` (PK), `title`, `subject`, `type`, `description`, `file_url`, `file_name`, `file_size`, `tags` (JSONB), `is_favorite`, `location_name`, `lat`, `long`, `owner_id` (FK `users.id`), `author_email`, `created_at`, `updated_at`.
  - Bảng `permissions`: `id` (PK), `document_id` (FK `documents.id`), `user_id` (FK `users.id`), `role` ('viewer' | 'editor'), `created_at`, ràng buộc `UNIQUE(document_id, user_id)`.

### 4. CHECKLIST 4: CHỨC NĂNG ỨNG DỤNG & QUẢN LÝ QUYỀN CHIA SẺ
- **Tải tệp lên:** `DocumentFormModal` tích hợp `FilePicker` chọn tệp -> tải lên Firebase Storage -> lấy downloadURL.
- **Hiển thị danh sách & Tìm kiếm:** Tích hợp bộ lọc nguồn "Của tôi" (Chủ sở hữu) / "Được chia sẻ", kết hợp tìm kiếm đa trường (tiêu đề, môn học, tag, mô tả).
- **Cập nhật Metadata:** Chủ sở hữu và Editor có thể sửa thông tin; Viewer bị vô hiệu hóa nút sửa.
- **Chia sẻ tài liệu qua Email:** Hộp thoại `ShareDocumentDialog` tra cứu email trong bảng `users`, cấp quyền `viewer` hoặc `editor`.
- **Thu hồi quyền:** Nút thùng rác đỏ xóa quyền khỏi bảng `permissions`; người bị thu hồi lập tức mất quyền truy cập.

### 5. CHECKLIST 5: BẢO MẬT ROW LEVEL SECURITY (RLS) & KIỂM THỬ 3 TÀI KHOẢN
- **Row Level Security (RLS) bật trên cả 3 bảng:**
  - `users`: Cho phép người dùng đọc để tìm email; chỉ chính chủ mới được tạo/sửa hồ sơ của mình.
  - `documents`: 
    - `SELECT`: Cho phép nếu là Chủ sở hữu HOẶC có tên trong bảng `permissions`.
    - `INSERT`: Chỉ cho phép nếu `owner_id = current_user_id()`.
    - `UPDATE`: Cho phép Chủ sở hữu HOẶC người có quyền `role = 'editor'` trong `permissions`. Viewer bị từ chối!
    - `DELETE`: Duy nhất Chủ sở hữu mới được xóa.
  - `permissions`:
    - `SELECT`: Chủ sở hữu hoặc chính người được cấp quyền.
    - `INSERT` / `UPDATE` / `DELETE`: Duy nhất Chủ sở hữu mới có quyền cấp/sửa/thu hồi quyền chia sẻ.
- **Nguyên tắc an toàn Client:**
  - Tuyệt đối không đưa `service_role` key vào client; chỉ dùng public `anonKey`.
  - Không giả lập bảo mật bằng UI: RLS chặn ở tầng cơ sở dữ liệu PostgreSQL.
- **Kiểm thử tự động:**
  - `flutter analyze`: **No issues found!**
  - `flutter test`: **38/38 kiểm thử vượt qua (100% Passed)**, bao gồm 5 kiểm thử kịch bản RLS cho 3 tài khoản A, B, C và người lạ D.
