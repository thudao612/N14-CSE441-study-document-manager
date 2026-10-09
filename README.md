# 📚 N14-CSE441 - Study Document Manager (Firebase Cloud Integration)

Hệ thống Quản lý Tài liệu Học tập dành cho sinh viên - Báo cáo & Lập phương án Tích hợp Cloud (Firebase) cho môn học CSE441.

---


## 🚨 LƯU Ý QUAN TRỌNG (ĐỌC KỸ TRƯỚC KHÍ THAO TÁC GIT)

1. **TUYỆT ĐỐI KHÔNG PUSH TRỰC TIẾP LÊN NHÁNH MAIN / MASTER:**
   * Tất cả thành viên **chỉ được phép push code lên nhánh cá nhân** của mình (`feature/tv...`).
   * Mọi thay đổi muốn đưa vào `main`/`master` bắt buộc phải thông qua **Pull Request (PR)** và được Nhóm trưởng review.

2. **TỰ GIẢI QUYẾT CONFLICT VÀ CHỊU TRÁCH NHIỆM:**
   * Khi tạo Pull Request, nếu xảy ra xung đột code (Merge Conflict), **thành viên chủ sở hữu PR đó phải tự kiểm tra, giải quyết conflict** với nhánh `main` trên máy cục bộ trước khi gộp.
   * Cần trao đổi kĩ với các thành viên liên quan trước khi sửa/xóa code chung. **Thành viên tạo PR chịu trách nhiệm hoàn toàn** nếu việc merge code gây lỗi hoặc ảnh hưởng đến phần việc của người khác.

---

## 👥 Phân Công Nhiệm Vụ & Tên Nhánh (Branches)

Để tránh xung đột code, mỗi thành viên sẽ làm việc trên **một nhánh (branch) riêng** theo bảng dưới đây:

| Thành viên | Vai trò chính | Checklist | Tên nhánh (Branch Name) | Công việc phụ trách |
| :--- | :--- | :--- | :--- | :--- |
| **TV1** | Vương Tiến Dũng| **1, 2** | | • Phân tích 4 thành phần cốt lõi (Frontend, Backend, DB, Storage).<br>• Phân tích điểm nghẽn & hạn chế trên hạ tầng cũ. |
| **TV2** | **Nhóm trưởng** & Cloud Architect | **3, 4** |  | • Lựa chọn mô hình Public Cloud (Firebase/GCP).<br>• Thiết kế Sơ đồ Kiến trúc Cloud & Luồng dữ liệu (Data Flow). |
| **TV3** | TRỊNH MẠNH ĐỨC | **5, 6** |  | • Đánh giá Bảo mật, Chi phí & Hiệu suất.<br>• Khởi tạo Firebase Project, cài SHA-1, Google Auth & Rules. |
| **TV4** | TRẦN ĐỨC TRUNG | **6** | `feature/tv4-flutter-firebase` | • Tích hợp Firebase SDK vào Flutter.<br>• Thay DataSource in-memory bằng Cloud Firestore & Storage. |
| **TV5** | Phạm Kim Anh | **7** | • Thiết kế Slide thuyết trình & Tổng hợp tài liệu nộp bài. |

---------------

## 🚀 Hướng Dẫn Clone Và Tạo Nhánh Làm Việc

### 1. Clone dự án về máy
Mở Terminal / Git Bash và chạy các lệnh:

```bash
# Clone repository về máy
git clone https://github.com/thudao612/N14-CSE441-study-document-manager

# Di chuyển vào thư mục dự án
cd N14-CSE441-study-document-manager

# Tải các gói phụ thuộc Flutter
flutter pub get

---------------
### 2. Tạo và chuyển sang Nhánh làm việc cá nhân
# Cập nhật code mới nhất từ master
git checkout master
git pull origin master

# Tạo và chuyển sang nhánh riêng của mình (Thay tên nhánh tương ứng)
git checkout -b feature/tv1-analysis

### 3. Quy trình đẩy code

# 1. Kiểm tra các file đã sửa
git status

# 2. Lưu thay đổi vào commit
git add .
git commit -m "TV1: Hoan thanh Checklist 1 va 2 - Phan tich diem nghen"

# 3. Đẩy nhánh riêng lên GitHub
git push origin feature/tv1-analysis

---------------

🔀 Các bước xử lý Pull Request & Conflict:
1. Truy cập giao diện GitHub của Rep => Bấm Compare & pull request.
2.(Review chéo - Peer Review): Gán (Assign/Reviewer) 1 thành viên khác trong nhóm vào đọc code/báo cáo; Nhóm trưởng (TV2) làm Final Reviewer.
    Ví dụ: TV1 review cho TV2, TV3 review cho TV4, TV4 review cho TV5...
3.Nếu có Conflict:
  Mở Terminal dưới máy, chuyển về nhánh cá nhân và kéo code main mới nhất về để tự fix:
    Bashgit checkout feature/tv1-analysis
    git pull origin main
  Mở VS Code sửa hết các đoạn bị Conflict => Commit => Push lại lên nhánh cá nhân.
4. Thành viên được gán sẽ kiểm tra xem code/báo cáo có lỗi không, chạy thử ổn định thì bấm Approve.
5. Sau khi hết Conflict, nhóm trưởng nhận được báo cáo đã có 1 lượt Approve từ thành viên khác =>Kiểm tra nhanh lần cuối=> Bấm Merge Pull Request vào main.
