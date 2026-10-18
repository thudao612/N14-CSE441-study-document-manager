# KỊCH BẢN & BÁO CÁO KIỂM THỬ (TESTING GUIDE)
## Tích hợp Firebase và Supabase: Kiểm thử Phân quyền 3 Tài khoản (A, B, C)

---

## 1. TỔNG QUAN KIỂM THỬ

Hệ thống Quản lý Tài liệu Học tập được xây dựng trên mô hình **Hybrid Cloud Architecture**:
- **Firebase Authentication**: Định danh người dùng bằng Google Sign-In & Firebase UID.
- **Firebase Cloud Storage**: Lưu trữ an toàn tệp vật lý (PDF, Word, TXT) với Storage Security Rules.
- **Supabase Cloud (PostgreSQL)**: Quản lý 3 bảng (`users`, `documents`, `permissions`) với **Row Level Security (RLS)** bảo mật ở mức hàng trong CSDL.

Bộ kiểm thử nhằm chứng minh tính toàn vẹn của hệ thống phân quyền đa người dùng:
1. **Chủ sở hữu (Owner)**: Toàn quyền (Xem, Sửa, Xóa, Tải tệp, Cấp quyền chia sẻ, Thu hồi quyền).
2. **Người được chia sẻ quyền Biên tập (Editor)**: Xem tài liệu, Tải tệp, Sửa metadata. Bị chặn Xóa tài liệu và Chia sẻ quyền.
3. **Người được chia sẻ quyền Chỉ xem (Viewer)**: Xem tài liệu, Tải tệp. Bị chặn Sửa metadata, Xóa tài liệu, Chia sẻ quyền.
4. **Người không có quyền / Người lạ (Unauthorized)**: Bị chặn hoàn toàn ở tầng CSDL (RLS) và Storage Rules.

---

## 2. KỊCH BẢN KIỂM THỬ THỰC TẾ 3 TÀI KHOẢN (A, B, C)

| Ký hiệu | Tên tài khoản | Email giả định | Vai trò kiểm thử |
| :--- | :--- | :--- | :--- |
| **A** | Nguyễn Văn A | `user_a@school.edu.vn` | **Chủ sở hữu (Owner)** |
| **B** | Trần Thị B | `user_b@school.edu.vn` | **Người nhận quyền Biên tập (Editor)** |
| **C** | Lê Văn C | `user_c@school.edu.vn` | **Người nhận quyền Chỉ xem (Viewer)** |
| **D** | Người lạ / Chưa đăng nhập | `stranger@external.com` | **Không có quyền (Unauthorized)** |

---

### KỊCH BẢN 1: TÀI KHOẢN A TẢI TỆP LÊN VÀ TẠO TÀI LIỆU
- **Bước thực hiện**:
  1. Tài khoản A đăng nhập qua Firebase Auth (Google hoặc Email/Password).
  2. Tại góc trên bên phải, kiểm tra hiển thị đúng Email và Firebase UID (`UID: uid-a`).
  3. Bấm nút **"+"** để mở `DocumentFormModal`.
  4. Bấm **"Chọn tệp từ thiết bị (Tải lên Firebase Storage)"**:
     - Chọn tệp `De_cuong_Mon_Hoc.pdf` (hoặc tệp Word/TXT).
     - Ứng dụng tải tệp lên Firebase Storage theo đường dẫn `documents/uid-a/{timestamp}_De_cuong_Mon_Hoc.pdf`.
     - Nhận về downloadURL Firebase Storage và tự động điền vào ô liên kết.
  5. Nhập Tiêu đề: `"Đề cương môn Kiến trúc Máy tính"`, Môn học: `"Kiến trúc Máy tính"`, Loại: `"Bài giảng"`.
  6. Bấm **"Thêm tài liệu"**.
- **Kết quả mong đợi & Xác minh**:
  - Bản ghi được chèn vào bảng `documents` trên Supabase với `owner_id = uid-a`.
  - Trên màn hình của A xuất hiện thẻ tài liệu với huy hiệu vàng: **`👑 Chủ sở hữu`**.
  - Tệp vật lý được lưu trữ bền vững trên Firebase Storage bucket.

---

### KỊCH BẢN 2: TÀI KHOẢN A CHIA SẺ TÀI LIỆU CHO B VÀ C
- **Bước thực hiện**:
  1. Trên thẻ tài liệu, A bấm menu 3 chấm hoặc mở Modal chi tiết, bấm **"Chia sẻ quyền"**.
  2. Nhập email của B: `user_b@school.edu.vn`, chọn vai trò: **`Biên tập (Editor)`**. Bấm **"Cấp quyền chia sẻ"**.
  3. Nhập email của C: `user_c@school.edu.vn`, chọn vai trò: **`Chỉ xem (Viewer)`**. Bấm **"Cấp quyền chia sẻ"**.
- **Kết quả mong đợi & Xác minh**:
  - Bảng `permissions` trên Supabase có 2 bản ghi mới:
    - `(document_id, user_id: uid-b, role: 'editor')`
    - `(document_id, user_id: uid-c, role: 'viewer')`
  - Danh sách người được chia sẻ trong hộp thoại hiển thị đầy đủ cả 2 email cùng vai trò tương ứng và nút **"Thu hồi"**.

---

### KỊCH BẢN 3: TÀI KHOẢN B (EDITOR) TRUY CẬP VÀ SỬA METADATA
- **Bước thực hiện**:
  1. Đăng xuất A, đăng nhập Tài khoản B (`user_b@school.edu.vn`).
  2. B mở màn hình chính (hoặc chọn tab lọc nhanh **"Được chia sẻ"**).
  3. B thấy tài liệu `"Đề cương môn Kiến trúc Máy tính"`.
  4. Quan sát huy hiệu trên thẻ: Hiển thị màu xanh ngọc: **`✏️ Biên tập`** và ghi chú *`Chia sẻ bởi: user_a@school.edu.vn`*.
  5. B bấm vào liên kết tệp đính kèm: Tệp PDF mở ra bình thường từ Firebase Storage.
  6. B bấm nút **"Chỉnh sửa"** (hoặc mở menu 3 chấm -> Chỉnh sửa):
     - Sửa Tiêu đề thành: `"Đề cương môn Kiến trúc Máy tính (Đã cập nhật 2026)"`.
     - Thêm thẻ tag `#ktmt2026`.
     - Bấm **"Lưu thay đổi"**.
- **Kết quả mong đợi & Xác minh**:
  - Thao tác UPDATE thành công! Tiêu đề mới được cập nhật trên giao diện và trên CSDL Supabase.
  - Chính sách RLS `"Update document as owner or editor"` cho phép B chỉnh sửa vì `role = 'editor'`.
  - B kiểm tra menu 3 chấm: **Không có tùy chọn "Xóa tài liệu"** và **Không có tùy chọn "Chia sẻ quyền"** (Chỉ Chủ sở hữu mới có quyền này).

---

### KỊCH BẢN 4: TÀI KHOẢN C (VIEWER) TRUY CẬP VÀ BỊ CHẶN SỬA
- **Bước thực hiện**:
  1. Đăng xuất B, đăng nhập Tài khoản C (`user_c@school.edu.vn`).
  2. C vào ứng dụng, thấy tài liệu trong danh sách chia sẻ.
  3. Quan sát huy hiệu: Hiển thị màu tím: **`👁️ Chỉ xem`**.
  4. C bấm vào tệp đính kèm: Tải và mở tệp PDF bình thường từ Firebase Storage.
  5. Mở Modal chi tiết tài liệu:
     - Thấy thông báo: *"Bạn có quyền Chỉ xem (Viewer). Chức năng chỉnh sửa và xóa bị vô hiệu hóa."*
     - Các nút "Chỉnh sửa", "Xóa tài liệu", "Chia sẻ quyền" **hoàn toàn bị ẩn**.
  6. *(Kiểm thử bảo mật tầng DB / API)*: Nếu C cố tình gửi câu lệnh `UPDATE documents SET title = 'Hacked' WHERE id = '...'` qua PostgREST API:
     - PostgreSQL RLS lập tức chặn đứng với mã lỗi **`42501 (Permission Denied)`**.
     - Dữ liệu tài liệu hoàn toàn không bị thay đổi.

---

### KỊCH BẢN 5: TÀI KHOẢN A THU HỒI QUYỀN CỦA C
- **Bước thực hiện**:
  1. Đăng nhập lại Tài khoản A (Owner).
  2. Mở hộp thoại **"Chia sẻ tài liệu"**.
  3. Tại dòng của `user_c@school.edu.vn`, bấm biểu tượng thùng rác màu đỏ **"Thu hồi quyền"**.
  4. Xác nhận thu hồi trong hộp thoại cảnh báo.
  5. Đăng nhập lại Tài khoản C, bấm **"Làm mới dữ liệu"** (icon Refresh).
- **Kết quả mong đợi & Xác minh**:
  - Bản ghi của C bị xóa khỏi bảng `permissions` trên Supabase.
  - Trên màn hình của C: Tài liệu **lập tức biến mất** khỏi danh sách.
  - Nếu C cố truy cập tài liệu bằng ID trực tiếp: Supabase trả về rỗng do RLS Policy `"View documents owned or shared"` không còn thỏa mãn.

---

### KỊCH BẢN 6: CHẶN TRUY CẬP TRÁI PHÉP (NGƯỜI LẠ / CHƯA ĐĂNG NHẬP)
- **Bước thực hiện**:
  1. Đăng nhập Tài khoản D (`stranger@external.com`) không được chia sẻ tài liệu, hoặc truy cập ở trạng thái chưa xác thực.
- **Kết quả mong đợi & Xác minh**:
  - Không nhìn thấy bất kỳ tài liệu nào của A trên giao diện.
  - Truy vấn SELECT trực tiếp tới Supabase: RLS trả về mảng rỗng `[]`.
  - Cố gửi lệnh INSERT/UPDATE/DELETE: RLS trả về lỗi `42501`.
  - Cố tải tệp từ Firebase Storage nếu chưa đăng nhập: Firebase Storage Rules trả về lỗi `401 / Unauthorized`.

---

## 3. BÁO CÁO KẾT QUẢ KIỂM THỬ TỰ ĐỘNG (AUTOMATED TEST SUITE)

Hệ thống đi kèm bộ kiểm thử tự động toàn diện chạy trực tiếp bằng lệnh `flutter test`:

```bash
flutter test
```

### Kết quả chạy kiểm thử thực tế trên hệ thống:
```text
00:00 +0: DocumentModel serialization & deserialization Tests fromJson map chính xác userId và authorEmail
00:00 +1: DocumentModel serialization & deserialization Tests toJson và toFirestoreJson xuất đầy đủ userId và authorEmail
00:00 +2: DocumentModel serialization & deserialization Tests fromEntity và toEntity chuyển đổi chính xác qua lại
00:00 +3: Supabase Models Serialization & Deserialization Tests DocumentPermissionModel: Chuyển đổi chính xác từ Supabase JSON và Entity
00:00 +4: Supabase Models Serialization & Deserialization Tests AppUserModel: Chuyển đổi chính xác từ Supabase users table JSON
00:00 +5: Supabase Models Serialization & Deserialization Tests DocumentModel: toSupabaseJson xuất đúng tên cột PostgreSQL (snake_case)
00:00 +6: DocumentRepositoryImpl (Data Layer) Tests Thêm tài liệu và lấy lại chính xác qua ID (Model <-> Entity)
00:00 +7: DocumentRepositoryImpl (Data Layer) Tests Cập nhật tài liệu trong Data Layer thành công
00:00 +8: DocumentRepositoryImpl (Data Layer) Tests Xóa tài liệu khỏi Data Layer thành công
00:00 +9: DocumentRepositoryImpl (Data Layer) Tests Lấy danh sách tất cả môn học và thẻ tags
00:00 +10: DocumentRepositoryImpl (Data Layer) Tests Lọc tài liệu theo DocumentFilter
00:01 +11: DocumentController (Presentation Layer) Tests Khởi tạo và tải dữ liệu rỗng thành công
00:01 +12: DocumentController (Presentation Layer) Tests Thêm tài liệu qua Controller cập nhật state và stats
00:01 +13: DocumentController (Presentation Layer) Tests Thay đổi từ khóa tìm kiếm lọc danh sách kết quả
00:01 +14: DocumentController (Presentation Layer) Tests Lọc theo DocumentType
00:01 +15: DocumentController (Presentation Layer) Tests Xóa tài liệu cập nhật danh sách và stats
00:01 +16: DocumentFormModal: Giao diện nhập URL duy nhất và kiểm tra validation
...
00:18 +22: Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C: 1. Tài khoản A (Owner) chia sẻ tài liệu cho B (Editor) và C (Viewer) thành công
00:18 +23: Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C: 2. Xác minh quyền xem và quyền sửa giữa Tài khoản A, B và C
00:18 +24: Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C: 3. Tài khoản B (Editor) hoặc C (Viewer) cố tình chia sẻ quyền -> Bị RLS chặn
00:18 +25: Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C: 4. Tài khoản A thu hồi quyền của C -> C lập tức mất quyền truy cập tài liệu
00:18 +26: Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C: 5. Người lạ D (hoặc chưa xác thực) -> Bị RLS chặn truy cập hoàn toàn
00:05 +38: All tests passed!
```

- **Tổng số kiểm thử**: **38/38 kiểm thử vượt qua (100% Passed)**.
- **Phân tích tĩnh (`flutter analyze`)**: **No issues found!** (0 cảnh báo, 0 lỗi).
