# 📚 N14-CSE441 - Study Document Manager (Firebase Cloud Integration)

Hệ thống Quản lý Tài liệu Học tập dành cho sinh viên - Báo cáo & Lập phương án Tích hợp Cloud (Firebase) cho môn học CSE441.

---

## 👥 Phân Công Nhiệm Vụ & Tên Nhánh (Branches)

Để tránh xung đột code, mỗi thành viên sẽ làm việc trên **một nhánh (branch) riêng** theo bảng dưới đây:

| Thành viên | Vai trò chính | Checklist | Tên nhánh (Branch Name) | Công việc phụ trách |
| :--- | :--- | :--- | :--- | :--- |
| **TV1** | System Analyst | **1, 2** | `feature/tv1-analysis` | • Phân tích 4 thành phần cốt lõi (Frontend, Backend, DB, Storage).<br>• Phân tích điểm nghẽn & hạn chế trên hạ tầng cũ. |
| **TV2** | **Nhóm trưởng** & Cloud Architect | **3, 4** | `feature/tv2-architecture` | • Lựa chọn mô hình Public Cloud (Firebase/GCP).<br>• Thiết kế Sơ đồ Kiến trúc Cloud & Luồng dữ liệu (Data Flow). |
| **TV3** | Firebase Security Admin | **5, 6** | `feature/tv3-firebase-config` | • Đánh giá Bảo mật, Chi phí & Hiệu suất.<br>• Khởi tạo Firebase Project, cài SHA-1, Google Auth & Rules. |
| **TV4** | Flutter Integration Dev | **6** | `feature/tv4-flutter-firebase` | • Tích hợp Firebase SDK vào Flutter.<br>• Thay DataSource in-memory bằng Cloud Firestore & Storage. |
| **TV5** | Slide & Documentation | **7** | • Viết Hướng dẫn Setup Firebase chi tiết theo dự án nhóm.<br>• Thiết kế Slide thuyết trình & Tổng hợp tài liệu nộp bài. |

---

## 🚀 Hướng Dẫn Clone Và Tạo Nhánh Làm Việc

### 1. Clone dự án về máy
Mở Terminal / Git Bash và chạy các lệnh:

```bash
# Clone repository về máy
git clone [https://github.com/thudao612/N14-CSE441-study-document-manager.git]

# Di chuyển vào thư mục dự án
cd N14-CSE441-study-document-manager

# Tải các gói phụ thuộc Flutter
flutter pub get


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
