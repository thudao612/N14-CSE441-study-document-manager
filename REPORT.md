# BÁO CÁO DỰ ÁN
## ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP

## 1. Giới thiệu

**Study Document Manager** là ứng dụng Flutter hỗ trợ quản lý tài liệu học tập theo môn học. Người dùng có thể tạo, chỉnh sửa, xóa, tìm kiếm và lọc tài liệu; phân loại theo bài giảng, bài tập hoặc tài liệu tham khảo; gắn thẻ và đánh dấu yêu thích.

Giao diện sử dụng Material 3 với phong cách màu sắc và thẻ nội dung được dự án gọi là “Cashew Style”. Mã nguồn được tổ chức theo các tầng Domain, Data, Use Cases và Presentation. Đây là cấu trúc phân tầng của chính dự án, không phải một bản triển khai đầy đủ hay bản sao của ứng dụng Cashew.

## 2. Công nghệ sử dụng

| Công nghệ / thư viện | Vai trò |
| --- | --- |
| Flutter / Dart | Framework và ngôn ngữ phát triển ứng dụng |
| Material 3 | Thành phần và giao diện người dùng |
| Provider | Cung cấp `DocumentController` và cập nhật giao diện theo trạng thái |
| `file_picker` | Chọn tệp PDF, DOC, DOCX hoặc TXT |
| `url_launcher` | Mở liên kết Web |
| `open_filex` | Yêu cầu hệ điều hành mở tệp cục bộ |
| `uuid` | Tạo mã định danh cho tài liệu |
| `intl` | Hỗ trợ định dạng ngày giờ |

Thông tin dependency và phiên bản ràng buộc được khai báo trong `pubspec.yaml`.

## 3. Cấu trúc mã nguồn

```text
lib/
├── domain/
│   ├── entities/       # Document, DocumentType và DocumentFilter
│   └── repositories/   # Hợp đồng IDocumentRepository
├── data/
│   ├── datasources/    # DocumentLocalDataSourceImpl (lưu trong bộ nhớ)
│   ├── models/         # DocumentModel và ánh xạ JSON / Entity
│   └── repositories/   # DocumentRepositoryImpl
├── usecases/           # Thêm, sửa, xóa, tìm kiếm, truy xuất và thống kê
├── presentation/
│   ├── controllers/    # Trạng thái màn hình qua ChangeNotifier
│   ├── screens/        # Màn hình chính
│   ├── theme/          # Theme và bảng màu
│   ├── utils/          # Hỗ trợ hiển thị / mở tệp và liên kết
│   └── widgets/        # Thẻ, bộ lọc, biểu mẫu và modal chi tiết
└── main.dart           # Khởi tạo các thành phần và kết nối Provider

test/
├── data/
├── mocks/
├── presentation/
├── usecases/
└── widget_test.dart
```

## 4. Thiết kế và luồng xử lý

### 4.1. Domain

- `Document` biểu diễn tài liệu với tiêu đề, môn học, loại, mô tả, chuỗi `fileUrlOrPath`, thẻ, trạng thái yêu thích và thời điểm tạo/cập nhật.
- `DocumentFilter` chứa điều kiện tìm kiếm và lọc.
- `IDocumentRepository` định nghĩa hợp đồng truy xuất dữ liệu.
- `Document` sử dụng các trường bất biến và `copyWith` để tạo bản cập nhật.

`DocumentType` hiện import `IconData` và màu sắc từ Flutter Material. Vì vậy, dù các quy tắc nghiệp vụ được tách riêng, toàn bộ tầng Domain hiện chưa hoàn toàn độc lập với Flutter.

### 4.2. Data

- `DocumentModel` chuyển đổi giữa dữ liệu dạng JSON và Entity.
- `DocumentRepositoryImpl` hiện thực `IDocumentRepository`, ánh xạ Model/Entity và thực hiện tìm kiếm, lọc.
- `DocumentLocalDataSourceImpl` cung cấp dữ liệu mẫu và lưu danh sách tài liệu trong một danh sách ở bộ nhớ.

Data Source hiện **không** ghi dữ liệu xuống SQLite, tệp hay dịch vụ đám mây. Các thay đổi trong phiên chạy không được bảo đảm tồn tại sau khi ứng dụng khởi động lại. Việc có `toJson`/`fromJson` trong Model không đồng nghĩa JSON đang được dùng làm kho lưu trữ.

### 4.3. Use Cases

- Thêm và cập nhật tài liệu: kiểm tra tiêu đề (ít nhất 2 ký tự), môn học; chuẩn hóa thẻ; tạo ID hoặc cập nhật thời điểm sửa.
- Xóa tài liệu theo ID.
- Tìm kiếm theo tiêu đề, môn học, mô tả và thẻ; lọc theo loại, môn học, thẻ và trạng thái yêu thích.
- Lấy danh sách, môn học, thẻ và thống kê tổng số tài liệu, số lượng theo loại, yêu thích và môn học.

### 4.4. Presentation

`DocumentController` sử dụng `ChangeNotifier` để quản lý danh sách, kết quả lọc, thống kê, trạng thái tải và lỗi. `main.dart` tạo các phụ thuộc, truyền chúng vào Controller và đăng ký Controller qua Provider.

Giao diện chính gồm phần thống kê, tìm kiếm, bộ lọc và danh sách thẻ tài liệu. Biểu mẫu hỗ trợ thêm/sửa thông tin và chọn tệp; modal chi tiết hiển thị thông tin tài liệu, cho phép sao chép chuỗi đính kèm và mở liên kết hoặc yêu cầu mở tệp cục bộ.

## 5. Tệp đính kèm và hỗ trợ Web

Trình chọn tệp chỉ chấp nhận các định dạng PDF, DOC, DOCX và TXT. Lệnh chọn tệp bật `withData: true`. Trên Web, ứng dụng dùng `file.name` thay vì truy cập `file.path`, vì đường dẫn tệp không khả dụng theo cách này trên Web; trên nền tảng khác, ứng dụng dùng đường dẫn nếu có và dự phòng về tên tệp.

Hiện tại, biểu mẫu chỉ đưa tên tệp hoặc đường dẫn vào trường `fileUrlOrPath`. Dù bytes được yêu cầu từ `FilePicker`, ứng dụng **chưa lưu bytes vào Entity, Data Source hay kho bền vững**. Do đó, việc chọn tệp trên Web hiện chỉ ghi nhận tên tệp, không lưu nội dung và không đảm bảo có thể mở lại tệp sau đó. Mở tài liệu Web trực tiếp từ bytes cũng chưa được triển khai. Liên kết HTTP/HTTPS được xử lý riêng bằng `url_launcher`.

## 6. Kiểm thử và phân tích tĩnh

Đã chạy kiểm chứng trong môi trường dự án:

- `flutter test`: **26/26 kiểm thử vượt qua** — bao gồm kiểm thử Repository, Controller, Use Cases và một Widget Test.
- `flutter analyze`: **No issues found**.

Các kiểm thử bao phủ thao tác dữ liệu, xác thực đầu vào, tìm kiếm/lọc, cập nhật trạng thái Controller và khởi tạo giao diện. Báo cáo này không tuyên bố đã đo độ bao phủ mã nguồn.

## 7. Giới hạn hiện tại và hướng phát triển

1. Thay Data Source in-memory bằng lưu trữ bền vững phù hợp với mục tiêu triển khai.
2. Nếu cần quản lý tệp thực sự, thiết kế chỗ lưu nội dung/định danh tệp và cập nhật Model, Entity, Repository cùng luồng mở tệp. Với Web, cần dùng bytes hoặc giải pháp lưu trữ Web phù hợp thay cho đường dẫn cục bộ.
3. Tách `IconData` và màu sắc ra khỏi Domain nếu mục tiêu là giữ tầng nghiệp vụ thuần Dart, độc lập framework.
4. Bổ sung kiểm thử cho chọn tệp và hành vi Web sau khi hoàn thiện luồng lưu trữ tệp.

## 8. Kết luận

Dự án hiện cung cấp một ứng dụng Flutter quản lý tài liệu với các thao tác CRUD, tìm kiếm, lọc, thẻ, yêu thích và thống kê. Mã nguồn tách biệt giao diện, use case, repository và data source ở mức cấu trúc; các kiểm thử hiện có cùng phân tích tĩnh đều đạt. Những điểm cần lưu ý trước khi xem đây là giải pháp sử dụng thực tế là dữ liệu chưa được lưu bền vững và nội dung tệp đính kèm chưa được lưu hoặc xử lý lại trên Web.
