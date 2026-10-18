# 📚 N14-CSE441 - Study Document Manager (Cloud Integration)

Hệ thống Quản lý Tài liệu Học tập dành cho sinh viên - Báo cáo & Lập phương án Tích hợp Cloud (Firebase Authentication, Firebase Storage & Supabase PostgreSQL) cho môn học CSE441.

---

## 🚨 LƯU Ý QUAN TRỌNG (ĐỌC KỸ TRƯỚC KHI THAO TÁC GIT)

1. **TUYỆT ĐỐI KHÔNG PUSH TRỰC TIẾP LÊN NHÁNH `master` / `main`:**
   * Tất cả các thành viên **chỉ được phép làm việc và push code lên nhánh cá nhân** của mình (`feature/tv...`).
   * Nhánh `master` là nhánh bảo vệ, chỉ nhận code thông qua **Pull Request (PR)** đã được kiểm thử và phê duyệt.

2. **QUY TRÌNH REVIEW CHÉO & PHÊ DUYỆT (PEER REVIEW & APPROVAL):**
   * Mọi Pull Request bắt buộc phải được gán ít nhất **1 thành viên khác kiểm thử chéo (Reviewer)** kéo về chạy thử và bấm **Approve**.
   * **Nhóm trưởng (Đào Hà Thu)** là người kiểm tra tổng thể lần cuối và thực hiện **Merge Pull Request** vào nhánh `master`.

3. **TỰ GIẢI QUYẾT CONFLICT VÀ CHỊU TRÁCH NHIỆM:**
   * Khi tạo Pull Request, nếu xảy ra xung đột code (Merge Conflict), **thành viên chủ sở hữu PR phải tự kéo code `master` về máy cục bộ và giải quyết conflict** trước khi gộp.
   * Cần trao đổi kỹ với các thành viên liên quan trước khi sửa hoặc xóa code chung.
   * **Thành viên tạo PR chịu trách nhiệm hoàn toàn** nếu việc gộp code gây lỗi hoặc ảnh hưởng đến phần việc của người khác.

---

## 👥 Bảng Phân Công Nhiệm Vụ & Tên Nhánh (Branches)

Để đảm bảo tiến độ và tránh xung đột mã nguồn, mỗi thành viên sẽ làm việc độc lập trên **nhánh cá nhân (branch)** theo bảng phân công dưới đây:

| STT | Thành viên | Vai trò | Checklist | Tên nhánh cá nhân (Branch Name) | Trọng tâm công việc |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **TV1** | **Đào Hà Thu** | **Nhóm trưởng** (Team Leader) | **CL1** | `feature/tv1-project-setup` | • Khảo sát, kiểm tra dự án hiện tại, đọc hiểu mã nguồn, giữ nguyên cấu hình Firebase sẵn có.<br>• Kế thừa và bảo toàn kiến trúc Clean Architecture 4 tầng.<br>• Phân tích 4 thành phần cốt lõi và các điểm nghẽn hạ tầng cũ.<br>• Thiết lập quy chuẩn Git, review chéo và Final Approver duyệt Merge PR. |
| **TV2** | **Phạm Kim Anh** | Thành viên phát triển | **CL2** | `feature/tv2-firebase-auth` | • Tích hợp Firebase Authentication (Google Sign-In, Email/Password, Anonymous).<br>• Quản lý phiên đăng nhập/đăng xuất, điều hướng bảo vệ qua `FirebaseAuthGate`.<br>• Định danh người dùng bằng Firebase UID; hiển thị email và UID trên giao diện.<br>• Tự động đồng bộ hồ sơ đăng nhập người dùng vào bảng `users`. |
| **TV3** | **Vương Tiến Dũng** | Thành viên phát triển | **CL3** | `feature/tv3-storage-supabase` | • Tích hợp Firebase Cloud Storage lưu trữ tệp nhị phân (PDF, DOCX, TXT).<br>• Xây dựng quy tắc bảo mật `storage.rules` (chặn tệp > 50MB, kiểm tra UID).<br>• Thiết kế Schema PostgreSQL 3 bảng (`users`, `documents`, `permissions`) trên Supabase.<br>• Xây dựng các DTO Models chuyển đổi linh hoạt JSON và Entity. |
| **TV4** | **Trần Đức Trung** | Thành viên phát triển | **CL4** | `feature/tv4-app-features` | • Xây dựng Modal tải tệp `DocumentFormModal` tích hợp `FilePicker`.<br>• Quản lý danh sách, tìm kiếm đa trường và bộ lọc nhanh ("Tất cả", "Của tôi", "Được chia sẻ", "Yêu thích").<br>• Thiết kế `DocumentCard` hiển thị huy hiệu vai trò (`👑 Chủ sở hữu`, `✏️ Biên tập`, `👁️ Chỉ xem`).<br>• Hiện thực hộp thoại `ShareDocumentDialog`: chia sẻ qua email và thu hồi quyền. |
| **TV5** | **Trịnh Mạnh Đức** | Thành viên phát triển | **CL5** | `feature/tv5-rls-security` | • Kích hoạt Row Level Security (RLS) cho cả 3 bảng trên Supabase.<br>• Thiết lập chính sách bảo mật RLS, tích hợp Firebase JWT qua hàm `current_user_id()`.<br>• Tuân thủ an toàn Client: chỉ dùng Public `anonKey`, không dùng `service_role key`.<br>• Xây dựng kịch bản & bộ test phân quyền 3 tài khoản (A - Owner, B - Editor, C - Viewer, D - Stranger). |
| **Nhóm** | **Cả 5 thành viên**  | Cả nhóm | **CL6** | Nhánh chính: `master` |Kiểm thử|

---

## 📋 Nội Dung Chi Tiết Các Checklist (CL1 – CL6)

### 📌 Checklist 1 (CL1): Kiểm tra dự án hiện tại & Kế thừa kiến trúc
* **Phụ trách:** Đào Hà Thu (TV1 - Nhóm trưởng)
* **Tên nhánh:** `feature/tv1-project-setup`
* **Nội dung công việc:**
  1. Đọc và phân tích toàn bộ mã nguồn hiện tại, nắm vững luồng xử lý và cấu trúc Clean Architecture 4 tầng: Domain, Data, Use Cases, Presentation.
  2. Giữ nguyên cấu hình Firebase đang hoạt động ổn định (`firebase_options.dart`, `firebase.json`), không tạo mới dự án để tránh xung đột cấu hình.
  3. Phân tích hiện trạng 4 thành phần cốt lõi: Frontend, Backend/API, Database, File Storage.
  4. Xác định các điểm nghẽn của hệ thống ban đầu (mất dữ liệu khi khởi động lại, tệp đính kèm chưa lưu nội dung, thiếu xác thực và phân quyền).
  5. Xây dựng quy chuẩn làm việc Git, tạo khung mẫu PR và phân công nhiệm vụ cho nhóm.

### 📌 Checklist 2 (CL2): Firebase Authentication & Quản lý danh tính
* **Phụ trách:** Phạm Kim Anh (TV2)
* **Tên nhánh:** `feature/tv2-firebase-auth`
* **Nội dung công việc:**
  1. Triển khai chức năng Đăng nhập bằng Google (`GoogleAuthProvider`), Email/Password và Anonymous.
  2. Xây dựng giao diện đăng nhập (`AuthSignInScreen`) và cổng điều hướng (`FirebaseAuthGate`) bảo vệ các màn hình chính.
  3. Xử lý chức năng Đăng xuất an toàn, tự động dọn dẹp phiên làm việc.
  4. Định danh người dùng thống nhất bằng **Firebase UID** trên toàn bộ hệ thống; hiển thị thông tin Email, Avatar và UID trên giao diện người dùng.
  5. Tự động đồng bộ thông tin tài khoản người dùng đăng nhập vào bảng `users` trên CSDL để phục vụ kiểm tra phân quyền.

### 📌 Checklist 3 (CL3): Firebase Storage & Thiết kế CSDL Supabase
* **Phụ trách:** Vương Tiến Dũng (TV3)
* **Tên nhánh:** `feature/tv3-storage-supabase`
* **Nội dung công việc:**
  1. Tích hợp Firebase Cloud Storage thông qua `FirebaseDocumentStorageRepository` để lưu trữ tệp nhị phân thực tế (PDF, Word, TXT) theo cấu trúc đường dẫn `documents/{userId}/{timestamp}_{fileName}`.
  2. Viết file quy tắc bảo mật `storage.rules`: yêu cầu xác thực `request.auth != null`, giới hạn dung lượng tải lên dưới 50MB và chỉ cho phép chủ sở hữu xóa tệp.
  3. Thiết kế CSDL quan hệ PostgreSQL trên Supabase gồm 3 bảng chuẩn hóa:
     * `users`: Lưu thông tin định danh và email của người dùng.
     * `documents`: Lưu trữ siêu dữ liệu tài liệu, liên kết tệp và mã chủ sở hữu (`owner_id`).
     * `permissions`: Quản lý quyền chia sẻ tài liệu giữa các người dùng (`viewer` / `editor`).
  4. Xây dựng các lớp Model chuyển đổi (DTO): `DocumentModel`, `DocumentPermissionModel`, `AppUserModel`.

### 📌 Checklist 4 (CL4): Chức năng ứng dụng & Giao diện phân quyền chia sẻ
* **Phụ trách:** Trần Đức Trung (TV4)
* **Tên nhánh:** `feature/tv4-app-features`
* **Nội dung công việc:**
  1. Xây dựng Modal tạo và chỉnh sửa tài liệu (`DocumentFormModal`): tích hợp `FilePicker` chọn tệp từ máy, tự động tải lên Cloud Storage và điền URL tải xuống.
  2. Nâng cấp danh sách tài liệu với bộ lọc trạng thái nhanh: **"Tất cả"**, **"Của tôi"**, **"Được chia sẻ"**, **"Yêu thích"** cùng thanh tìm kiếm từ khóa đa trường.
  3. Thiết kế thẻ tài liệu (`DocumentCard`) hiển thị trực quan các huy hiệu vai trò:
     * 👑 **Chủ sở hữu** (Owner): Toàn quyền xem, sửa, xóa, chia sẻ.
     * ✏️ **Biên tập** (Editor): Xem tài liệu, tải tệp, sửa metadata.
     * 👁️ **Chỉ xem** (Viewer): Chỉ xem tài liệu và tải tệp; bị vô hiệu hóa nút sửa và xóa.
  4. Hiện thực hộp thoại `ShareDocumentDialog`: tìm kiếm người dùng theo email, cấp quyền `viewer` hoặc `editor` và chức năng thu hồi quyền chia sẻ.

### 📌 Checklist 5 (CL5): Bảo mật Row Level Security (RLS) & Kiểm thử 3 tài khoản
* **Phụ trách:** Trịnh Mạnh Đức (TV5)
* **Tên nhánh:** `feature/tv5-rls-security`
* **Nội dung công việc:**
  1. Kích hoạt tính năng **Row Level Security (RLS)** trên cả 3 bảng (`users`, `documents`, `permissions`) trong PostgreSQL.
  2. Viết các hàm và chính sách bảo mật (Policies):
     * Hàm `current_user_id()` trích xuất UID từ Firebase JWT.
     * Chặn người ngoài xem tài liệu riêng tư; chỉ chủ sở hữu mới có quyền xóa tài liệu và quản lý quyền chia sẻ; người có quyền `editor` được cập nhật thông tin; người có quyền `viewer` bị chặn sửa ở tầng CSDL.
  3. Tuân thủ nguyên tắc an toàn phía Client: chỉ sử dụng Public `anonKey`, **tuyệt đối không đưa `service_role key` vào ứng dụng Flutter**.
  4. Xây dựng kịch bản kiểm thử phân quyền thực tế với 3 tài khoản (A - Chủ sở hữu, B - Biên tập, C - Chỉ xem) và tài khoản lạ D; xây dựng bộ kiểm thử tự động với UseCase tests.

### 📌 Checklist 6 (CL6): Nhiệm vụ chung cả nhóm (Hoàn thiện tổng thể)
* **Phụ trách:** Cả nhóm
* **Nhánh tích hợp:** `master`
* **Nội dung công việc:**
 Kiểm thử hệ thống, báo cáo, trình bày

---

## 🚀 Hướng Dẫn Quy Trình Git & Làm Việc Nhóm

Quy trình làm việc chuẩn mực giúp nhóm phối hợp mượt mà, tránh mất mã nguồn và hạn chế tối đa xung đột.

```
[Nhánh master] ─── (Checkout & Pull) ───> [Nhánh cá nhân feature/tv...]
                                                     │
                                               (Code & Commit)
                                                     │
                                            (Chạy flutter test)
                                                     │
                                                (Git Push)
                                                     │
                                                     ▼
                                            [Mở Pull Request]
                                                     │
                                         (Review chéo & Approve)
                                                     │
                                         (Giải quyết Conflict)
                                                     │
[Nhánh master] <─── (Nhóm trưởng Merge) ─────────────┘
```

---

### Bước 1: Clone dự án về máy cục bộ

Mở Terminal / Git Bash và thực hiện:

```bash
# 1. Clone repository về máy
git clone https://github.com/thudao612/study-document-manager.git

# 2. Di chuyển vào thư mục dự án
cd study-document-manager

# 3. Tải toàn bộ thư viện phụ thuộc của Flutter
flutter pub get

# 4. Kiểm tra phân tích tĩnh mã nguồn
flutter analyze
```

---

### Bước 2: Tạo và chuyển sang nhánh làm việc cá nhân

Trước khi tạo nhánh mới, luôn đảm bảo nhánh `master` cục bộ của bạn là phiên bản mới nhất:

```bash
# 1. Chuyển về nhánh master
git checkout master

# 2. Kéo code mới nhất từ GitHub về
git pull origin master
```

Sau đó, tạo và chuyển sang nhánh riêng của mình theo đúng mã thành viên và checklist:

```bash
# Thành viên 1 (Đào Hà Thu - CL1):
git checkout -b feature/tv1-project-setup

# Thành viên 2 (Phạm Kim Anh - CL2):
git checkout -b feature/tv2-firebase-auth

# Thành viên 3 (Vương Tiến Dũng - CL3):
git checkout -b feature/tv3-storage-supabase

# Thành viên 4 (Trần Đức Trung - CL4):
git checkout -b feature/tv4-app-features

# Thành viên 5 (Trịnh Mạnh Đức - CL5):
git checkout -b feature/tv5-rls-security
```

---

### Bước 3: Phát triển tính năng, kiểm thử và Commit code

Trong quá trình lập trình, hãy commit thường xuyên theo từng phần việc nhỏ đã hoàn thành.

```bash
# 1. Kiểm tra danh sách file đã thay đổi
git status

# 2. Kiểm tra chất lượng mã nguồn trước khi commit
flutter analyze
flutter test

# 3. Thêm các file đã thay đổi vào vùng chuẩn bị commit
git add .

# 4. Tạo commit với thông điệp rõ ràng theo chuẩn
# Cú pháp: git commit -m "feat(CL<số>): <nội dung công việc>"
git commit -m "feat(CL1): Kế thừa cấu trúc Clean Architecture và phân tích điểm nghẽn"
```

*Ví dụ thông điệp commit chuẩn cho từng thành viên:*
* TV1: `git commit -m "feat(CL1): Hoàn thành CL1"`
* TV2: `git commit -m "feat(CL2): Hoàn thành CL2"`
* TV3: `git commit -m "feat(CL3): Hoàn thành CL3"`
* TV4: `git commit -m "feat(CL4): Hoàn thành CL4"`
* TV5: `git commit -m "feat(CL5): Hoàn thành CL5"`

---

### Bước 4: Đẩy nhánh riêng lên GitHub (Push)

Đẩy nhánh cá nhân lên remote repository:

```bash
# Cú pháp: git push -u origin <tên-nhánh-cá-nhân>
git push -u origin feature/tv1-project-setup
```

> [!WARNING]
> **Tuyệt đối không chạy lệnh `git push origin master` hoặc sử dụng cờ `-f` (force push).**

---

### Bước 5: Tạo Pull Request (PR) trên GitHub

1. Truy cập vào kho lưu trữ trên GitHub: `https://github.com/thudao612/study-document-manager`.
2. Bạn sẽ thấy thanh thông báo vàng với nút **Compare & pull request** cho nhánh vừa push -> Nhấp vào nút này.
3. Cấu hình nhánh:
   * **base:** `master`
   * **compare:** `<nhánh-cá-nhân-của-bạn>`
4. Đặt tiêu đề PR rõ ràng:
   * `[TV1 - CL1] Hoàn thành CL1`
   * `[TV2 - CL2] Hoàn thành CL2`
   * `[TV3 - CL3] Hoàn thành CL3`
   * `[TV4 - CL4] Hoàn thành CL4`
   * `[TV5 - CL5] Hoàn thành CL5`
5. Điền nội dung mô tả PR theo mẫu:
   ```markdown
   ### 📌 Checklist phụ trách: CL...
   - **Thành viên:** <Họ và tên>
   - **Tên nhánh:** feature/tv...

   ### 📝 Mô tả công việc đã hoàn thành:
   - Đã hiện thực chức năng: ...
   - Đã cập nhật các file: ...

   ### 🧪 Kết quả kiểm thử:
   - flutter analyze: No issues found
   - flutter test: All tests passed
   ```
6. Bấm **Create pull request**.

---

### Bước 6: Quy trình Kiểm thử chéo (Cross-Testing & Peer Review)

Nhóm áp dụng mô hình **Review chéo vòng tròn** để đảm bảo tất cả thành viên đều hiểu rõ mã nguồn của đồng đội:

```
[TV1: Đào Hà Thu]   ─── Review cho ───> [TV2: Phạm Kim Anh]
[TV2: Phạm Kim Anh] ─── Review cho ───> [TV3: Vương Tiến Dũng]
[TV3: Vương Tiến Dũng] ─ Review cho ───> [TV4: Trần Đức Trung]
[TV4: Trần Đức Trung] ─ Review cho ───> [TV5: Trịnh Mạnh Đức]
[TV5: Trịnh Mạnh Đức] ─ Review cho ───> [TV1: Đào Hà Thu]
```
*(Đồng thời Nhóm trưởng Đào Hà Thu giữ vai trò Final Reviewer cho tất cả các PR).*

**Các bước Reviewer thực hiện kiểm thử chéo:**
1. Mở Terminal trên máy cục bộ, kéo nhánh của người cần review về máy:
   ```bash
   # Cập nhật danh sách nhánh mới nhất từ GitHub
   git fetch origin

   # Chuyển sang nhánh của đồng đội
   git checkout feature/tv2-cl2-firebase-auth
   git pull origin feature/tv2-cl2-firebase-auth
   ```
2. Chạy kiểm tra mã nguồn và giao diện:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```
3. Đánh giá theo các tiêu chí:
   * Mã nguồn có phân tầng đúng Clean Architecture không?
   * Tính năng có chạy mượt mà, đúng yêu cầu checklist không?
   * Có phát sinh cảnh báo hoặc lỗi biên dịch nào không?
4. Truy cập giao diện PR trên GitHub:
   * Nếu có điểm chưa ổn: Ghi chú nhận xét cụ thể tại phần **Files changed**.
   * Nếu mọi thứ đã chuẩn: Nhấp vào **Review changes** -> Chọn **Approve** -> Bấm **Submit review**.

---

### Bước 7: Quy trình Xử lý Merge Conflict (Xung đột mã nguồn)

Khi hai thành viên cùng sửa đổi một file hoặc một dòng code, GitHub sẽ báo trạng thái **"This branch has conflicts that must be resolved"**. Thành viên tạo PR phải tự xử lý xung đột theo quy trình sau:

1. **Chuyển về nhánh cá nhân trên máy cục bộ:**
   ```bash
   git checkout feature/tv...
   ```
2. **Kéo code mới nhất từ nhánh `master` về nhánh cá nhân:**
   ```bash
   git pull origin master
   ```
3. **Mở trình soạn thảo (VS Code / Android Studio) để xử lý xung đột:**
   * Git sẽ đánh dấu vùng bị xung đột bằng các ký hiệu:
     ```text
     <<<<<<< HEAD (Mã nguồn hiện tại trên nhánh cá nhân của bạn)
     Mã nguồn do bạn viết
     =======
     Mã nguồn mới nhất trên nhánh master từ đồng đội khác
     >>>>>>> master
     ```
   * Trao đổi trực tiếp với thành viên viết đoạn code liên quan để thống nhất nội dung cần giữ lại.
   * Trên VS Code, bạn có thể bấm nhanh vào các tùy chọn:
     * **Accept Current Change:** Giữ nguyên code của bạn.
     * **Accept Incoming Change:** Giữ nguyên code từ `master`.
     * **Accept Both Changes:** Giữ cả hai đoạn code.
   * **Xóa bỏ hoàn toàn các dòng cờ đánh dấu** (`<<<<<<<`, `=======`, `>>>>>>>`).

4. **Chạy lại kiểm thử để xác nhận code không bị lỗi sau khi sửa:**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Đánh dấu đã sửa xung đột và tạo commit merge:**
   ```bash
   git add .
   git commit -m "fix(merge): giải quyết conflict với nhánh master"
   ```

6. **Đẩy lại nhánh cá nhân lên GitHub:**
   ```bash
   git push origin feature/tv...
   ```
7. Trạng thái trên Pull Request sẽ tự động chuyển thành **"This branch has no conflicts with the base branch"**.

---

### Bước 8: Duyệt và Gộp Pull Request (Merge PR) vào master

Sau khi PR thỏa mãn đồng thời các điều kiện:
* Đã có ít nhất **1 lượt Approve** từ thành viên kiểm thử chéo.
* Không còn xung đột code (No conflicts).
* Kiểm thử tự động và phân tích mã đều đạt kết quả tốt.

**Nhóm trưởng (Đào Hà Thu)** sẽ kiểm tra tổng thể lần cuối và nhấn nút **Merge pull request** -> Chọn **Confirm merge**.

---

## 📂 Tài Liệu Kỹ Thuật Tham Khảo

Toàn bộ tài liệu chi tiết của dự án được lưu trữ tại thư mục gốc và thư mục `docs/`:

* 📖 [`REPORT.md`](file:///c:/Users/HP/Desktop/study-document-manager/REPORT.md): Báo cáo tổng quan kiến trúc và công nghệ sử dụng trong dự án.
* ✅ [`docs/CHECKLIST.md`](file:///c:/Users/HP/Desktop/study-document-manager/docs/CHECKLIST.md): Chi tiết 5 Checklist nhiệm vụ và bằng chứng hoàn thành.
* 🧪 [`docs/TESTING.md`](file:///c:/Users/HP/Desktop/study-document-manager/docs/TESTING.md): Kịch bản kiểm thử phân quyền 3 tài khoản thực tế (A, B, C) và hướng dẫn chạy test tự động.
* ⚙️ [`docs/SETUP.md`](file:///c:/Users/HP/Desktop/study-document-manager/docs/SETUP.md): Hướng dẫn cấu hình Firebase Console và Supabase Dashboard.
* ☁️ [`CLOUD_ARCHITECTURE_ANALYSIS.md`](file:///c:/Users/HP/Desktop/study-document-manager/CLOUD_ARCHITECTURE_ANALYSIS.md): Phân tích chi tiết kiến trúc Cloud, mô hình BaaS và đánh giá bảo mật, chi phí, hiệu suất.
