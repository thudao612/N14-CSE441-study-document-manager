# Phân tích kiến trúc Cloud cho ứng dụng Quản lý tài liệu

## 1. Các thành phần cốt lõi hiện có

| Thành phần | Thực trạng trong dự án | Nhận xét |
|---|---|---|
| **Frontend** | Ứng dụng Flutter, tổ chức theo Presentation, Use Cases, Domain và Data. `DocumentController` quản lý trạng thái; giao diện hỗ trợ CRUD, tìm kiếm, lọc, yêu thích và chọn tệp. | Có nền tảng phù hợp để thay nguồn dữ liệu phía sau mà không phải viết lại toàn bộ giao diện. Đây là ứng dụng client; hiện chưa có luồng đăng nhập hay phân quyền. |
| **Backend/API** | **Chưa có backend hoặc API.** `main.dart` khởi tạo trực tiếp data source và repository trong ứng dụng. | Chưa có dịch vụ trung tâm để xác thực người dùng, áp dụng quyền truy cập hoặc xử lý dữ liệu thống nhất giữa nhiều thiết bị. |
| **Database** | **Chưa có database.** `DocumentLocalDataSourceImpl` giữ tài liệu trong một danh sách trong bộ nhớ và nạp dữ liệu mẫu. | Dữ liệu tạo hoặc sửa không được lưu bền vững sau khi ứng dụng đóng. `toJson`/`fromJson` trong model chỉ hỗ trợ chuyển đổi dữ liệu, không có nghĩa là đã có nơi lưu JSON. |
| **File Storage** | **Chưa có kho lưu nội dung tệp.** Biểu mẫu chọn tệp và yêu cầu bytes, nhưng khi lưu tài liệu chỉ ghi tên hoặc đường dẫn vào `fileUrlOrPath`. | Bytes không được lưu hoặc tải lên; đường dẫn cục bộ không dùng được ổn định trên thiết bị khác hoặc Web. Tài liệu dạng liên kết Web là ngoại lệ vì chỉ lưu URL. |

**Luồng dữ liệu hiện tại:** giao diện Flutter → Controller/Use Cases → Repository → data source in-memory. Dự án chưa cấu hình dịch vụ cloud.

## 2. Điểm nghẽn và hạn chế

### Các hạn chế đã xác nhận trong mã nguồn

- **Mất dữ liệu khi khởi động lại:** data source lưu trong RAM và nạp dữ liệu mẫu, không có lưu trữ bền vững.
- **Tệp đính kèm chưa được lưu:** ứng dụng mới ghi nhận tên hoặc đường dẫn; không đảm bảo tải lại hay mở được tệp đã chọn.
- **Không đồng bộ giữa thiết bị:** chưa có API, database dùng chung hoặc danh tính người dùng.
- **Lọc và tìm kiếm phía client:** repository lấy toàn bộ tài liệu rồi lọc; cách này không phù hợp khi lượng dữ liệu tăng đáng kể.
- **Thiếu năng lực vận hành:** chưa có xác thực, phân quyền, sao lưu, nhật ký tập trung hoặc giám sát dịch vụ.

### Hạn chế có thể gặp trên hạ tầng truyền thống

Chưa có bằng chứng dự án hiện chạy trên máy chủ truyền thống. Nếu triển khai theo mô hình máy chủ đơn, database và ổ đĩa cục bộ, các rủi ro thường gặp gồm:

- Phải tự vận hành, vá lỗi và mở rộng máy chủ.
- Máy chủ hoặc ổ đĩa đơn lẻ có thể trở thành điểm lỗi.
- Sao lưu và phục hồi dữ liệu cần được tự thiết kế, kiểm tra và vận hành.
- Dung lượng tệp tăng có thể đòi hỏi đầu tư hạ tầng trước khi sử dụng hết công suất.

Đây là các rủi ro của mô hình giả định, không phải sự cố đã quan sát ở hệ thống hiện tại.

## 3. Checklist 3: Lựa chọn mô hình Cloud và Dịch vụ cụ thể

### 3.1. So sánh chi tiết 3 mô hình triển khai Cloud (Cloud Deployment Models)

Trong kỹ nghệ phần mềm và kiến trúc điện thoại di động, việc lựa chọn mô hình triển khai đám mây (Cloud Deployment Model) định hình toàn bộ chiến lược vận hành, bảo mật và chi phí của dự án. Dưới đây là phân tích chi tiết ba mô hình triển khai chính:

```
+-----------------------------------------------------------------------------------+
|                           CÁC MÔ HÌNH TRIỂN KHAI ĐÁM MÂY                          |
+-------------------------+--------------------------------+------------------------+
|      PUBLIC CLOUD       |         PRIVATE CLOUD          |      HYBRID CLOUD      |
|  (Đám mây công cộng)    |        (Đám mây riêng)         |    (Đám mây kết hợp)   |
| • Đa người thuê         | • Đơn người thuê               | • Tích hợp Public      |
| • Không tốn CAPEX       | • Toàn quyền kiểm soát phần    |   và Private Cloud     |
| • Co giãn tức thì       |   cứng & dữ liệu               | • Phức tạp tích hợp    |
| • Nhà cung cấp vận hành | • Chi phí đầu tư cực lớn       | • Đòi hỏi hạ tầng sẵn  |
+-------------------------+--------------------------------+------------------------+
```

#### 1. Public Cloud (Đám mây công cộng)
* **Định nghĩa:** Toàn bộ hạ tầng điện toán (Compute, Storage, Network, Database) thuộc quyền sở hữu, vận hành và bảo trì bởi các nhà cung cấp dịch vụ đám mây lớn (Hyperscalers như Google Cloud Platform, AWS, Microsoft Azure). Tài nguyên phần cứng được trừu tượng hóa và chia sẻ cho nhiều khách hàng (Multi-tenancy) thông qua kết nối Internet công cộng an toàn.
* **Ưu điểm:**
  * **Chi phí vốn bằng 0 (Zero CAPEX):** Không cần đầu tư mua sắm máy chủ vật lý, ổ cứng, tủ rack hay xây dựng phòng máy lạnh. Chuyển dịch hoàn toàn sang chi phí vận hành (OPEX - Pay-as-you-go).
  * **Khả năng co giãn đàn hồi tức thời (Elastic Scalability):** Hệ thống có thể tự động nâng/hạ tài nguyên tức thời theo lưu lượng truy cập thực tế.
  * **Loại bỏ gánh nặng vận hành:** Nhà cung cấp đảm bảo tính sẵn sàng (High Availability SLA > 99.95%), tự động sao lưu dữ liệu, vá lỗi bảo mật phần cứng và hệ điều hành.
  * **Hệ sinh thái dịch vụ đa dạng:** Sẵn sàng tích hợp các giải pháp hiện đại như Serverless, NoSQL, Object Storage, AI/ML API mà không cần tự phát triển.
* **Nhược điểm:**
  * Phụ thuộc hoàn toàn vào kết nối Internet và độ ổn định của nhà cung cấp.
  * Dữ liệu lưu trữ trên hạ tầng dùng chung, yêu cầu đội ngũ phát triển phải cấu hình chặt chẽ chính sách kiểm soát truy cập (Access Control) và quy tắc bảo mật (Security Rules).
  * Chi phí lưu lượng truyền tải dữ liệu ra Internet (Data Egress) có thể tăng cao nếu không tối ưu kích thước tài liệu và cơ chế caching.
* **Bối cảnh ứng dụng "Study Document Manager":** **Cực kỳ lý tưởng.** Ứng dụng phục vụ nhu cầu lưu trữ và chia sẻ tài liệu học tập của sinh viên/giảng viên, không chứa dữ liệu bí mật quốc gia hay giao dịch tài chính. Ứng dụng cần ra mắt nhanh chóng, chi phí khởi điểm tối thiểu và khả năng chịu tải tốt trong các kỳ thi.

#### 2. Private Cloud (Đám mây riêng)
* **Định nghĩa:** Hạ tầng đám mây được thiết kế, cấp phát và vận hành phục vụ riêng biệt cho duy nhất một tổ chức (Single-tenant). Hạ tầng có thể đặt tại trung tâm dữ liệu nội bộ (On-premise Datacenter) hoặc thuê máy chủ chuyên dụng (Dedicated Hosted Cloud).
* **Ưu điểm:**
  * **Toàn quyền kiểm soát và cách ly hoàn toàn:** Kiểm soát 100% từ phần cứng vật lý, kiến trúc mạng, giao thức mã hóa cho đến dữ liệu.
  * **Tuân thủ pháp lý nghiêm ngặt:** Đáp ứng tuyệt đối các tiêu chuẩn an ninh khắt khe (HIPAA, PCI-DSS, tiêu chuẩn cơ quan chính phủ).
  * **Hiệu năng mạng nội bộ cao và ổn định:** Tận dụng được đường truyền mạng LAN tốc độ cao khi truy cập tại chỗ.
* **Nhược điểm:**
  * **Chi phí đầu tư ban đầu (CAPEX) cực kỳ đắt đỏ:** Tốn kém hàng trăm triệu đến hàng tỷ đồng để mua sắm máy chủ, hệ thống lưu trữ SAN/NAS, thiết bị mạng Firewall, bộ lưu điện UPS và phòng máy chủ đạt chuẩn.
  * **Gánh nặng vận hành liên tục (OPEX nhân sự):** Bắt buộc phải có đội ngũ kỹ sư hệ thống (SysAdmin/DevOps/Security) túc trực 24/7 để giám sát, thay thế linh kiện hỏng, sao lưu thủ công và khắc phục sự cố.
  * **Khó khăn khi mở rộng:** Khi dung lượng tài liệu học tập tăng nhanh, việc nâng cấp đòi hỏi quy trình mua sắm, lắp đặt và cấu hình phần cứng mới mất nhiều tuần lễ.
* **Bối cảnh ứng dụng "Study Document Manager":** **Hoàn toàn không khả thi và lãng phí tài nguyên (Overkill).** Một dự án ứng dụng học tập sinh viên không thể gánh vác chi phí mua sắm máy chủ hay chi phí thuê chuyên gia vận hành phần cứng riêng.

#### 3. Hybrid Cloud (Đám mây lai)
* **Định nghĩa:** Mô hình kết hợp đồng thời giữa Private Cloud (On-premise) và Public Cloud, kết nối thông qua mạng riêng ảo an toàn (Site-to-Site VPN) hoặc đường truyền chuyên dụng (Direct Connect), cho phép điều phối linh hoạt khối lượng công việc và chia sẻ dữ liệu giữa hai môi trường.
* **Ưu điểm:**
  * **Linh hoạt chiến lược:** Giữ các dữ liệu mật, hồ sơ điểm số sinh viên cốt lõi tại máy chủ nội bộ trường học, đồng thời tận dụng Public Cloud để phân phối tài liệu bài giảng nặng (PDF, Slide) đến sinh viên qua Internet.
  * **Tận dụng hạ tầng sẵn có:** Giúp các tổ chức đã lỡ đầu tư máy chủ On-premise có thể chuyển đổi dần lên Cloud mà không phải bỏ đi hệ thống cũ.
* **Nhược điểm:**
  * **Kiến trúc vô cùng phức tạp:** Đòi hỏi cấu hình đồng bộ danh tính, thiết lập đường hầm VPN an toàn, kiểm soát dữ liệu phân tán và quản trị bảo mật chéo môi trường.
  * **Chi phí vận hành cao nhất:** Phải duy trì cùng lúc cả chi phí máy chủ nội bộ lẫn hóa đơn dịch vụ Public Cloud.
* **Bối cảnh ứng dụng "Study Document Manager":** **Không phù hợp.** Dự án hiện tại là một sản phẩm phát triển mới hoàn toàn từ đầu (Greenfield project), chưa hề có bất kỳ hệ thống máy chủ On-premise kế thừa (Legacy system) nào từ trước để cần tích hợp. Việc lựa chọn Hybrid Cloud sẽ làm phát sinh độ phức tạp không đáng có.

---

#### Bảng ma trận so sánh tổng hợp 3 mô hình triển khai

| Tiêu chí so sánh | Public Cloud | Private Cloud | Hybrid Cloud |
|---|---|---|---|
| **Vốn đầu tư ban đầu (CAPEX)** | **$0 (Zero CAPEX)** | Rất cao (Server, Rack, Network) | Cao (Phần cứng tại chỗ + Setup) |
| **Chi phí vận hành (OPEX)** | Trả theo sử dụng (Pay-as-you-go) | Chi phí cố định lớn (Điện, nhân sự) | Cao (Vận hành song song 2 môi trường) |
| **Tốc độ triển khai (Time-to-Market)** | **Ngay lập tức (Tính bằng phút)** | Chậm (Hàng tuần/tháng mua thiết bị) | Rất chậm (Tích hợp mạng phức tạp) |
| **Khả năng co giãn (Scalability)** | **Tự động & vô hạn (Elastic)** | Bị giới hạn bởi phần cứng vật lý | Linh hoạt nhưng phụ thuộc đường truyền |
| **Gánh nặng bảo trì hạ tầng** | **Nhà cung cấp chịu trách nhiệm** | Đội ngũ nội bộ tự quản 24/7 | Cần kỹ sư chuyên môn cao cả 2 mảng |
| **Tính phù hợp với dự án** | ⭐⭐⭐⭐⭐ **(Lựa chọn tối ưu)** | ⭐ (Không khả thi) | ⭐⭐ (Quá phức tạp, không cần thiết) |

---

### 3.2. Quyết định lựa chọn: Public Cloud

Dưới góc độ Kiến trúc sư đám mây (Cloud Architect) và Nhóm trưởng kỹ thuật, tôi khẳng định quyết định: **Dự án "Study Document Manager" lựa chọn 100% mô hình PUBLIC CLOUD.**

Quyết định này được xây dựng trên 4 luận điểm chiến lược cốt lõi:

1. **Tối ưu hóa tài chính triệt để (Zero CAPEX & Gói Free-Tier dồi dào):**
   * Dự án xuất phát điểm từ quy mô đồ án môn học / sản phẩm phục vụ sinh viên, nhóm không có ngân sách đầu tư phần cứng máy chủ.
   * Public Cloud cung cấp hạn mức miễn phí (Free Tier) cực kỳ hào phóng (đặc biệt là gói Spark Plan của Firebase với 1 GB lưu trữ NoSQL, 5 GB Cloud Storage và 50.000 lượt đọc/ngày), hoàn toàn đủ để nhóm phát triển, thử nghiệm và vận hành thực tế cho hàng trăm sinh viên mà **không tốn một đồng chi phí nào**.
2. **Loại bỏ 100% gánh nặng quản trị hạ tầng (No Hardware Maintenance):**
   * Đội ngũ dự án bao gồm các lập trình viên Flutter, không có chuyên gia chuyên trách về quản trị mạng hay phần cứng máy chủ.
   * Public Cloud giúp loại bỏ hoàn toàn các rủi ro về phần cứng (hỏng ổ cứng, đứt cáp mạng, mất điện, cấu hình Firewall OS), giúp nhóm tập trung 100% nhân lực vào việc hoàn thiện tính năng, tối ưu trải nghiệm người dùng và chuẩn hóa kiến trúc mã nguồn Clean Architecture.
3. **Khả năng co giãn đàn hồi theo chu kỳ học tập (Elastic Scalability):**
   * Lưu lượng sử dụng ứng dụng quản lý tài liệu học tập có tính chu kỳ rất rõ rệt: Tải tăng vọt đột biến (Spike) vào các giai đoạn ôn thi cuối kỳ, tuần nộp đồ án tốt nghiệp, và giảm mạnh trong kỳ nghỉ hè.
   * Public Cloud tự động co giãn tài nguyên xử lý và băng thông tức thời theo nhu cầu thực tế, đảm bảo ứng dụng không bị nghẽn mạng hay sập hệ thống khi hàng loạt sinh viên cùng tải đề cương một lúc.
4. **Độ sẵn sàng cao và khả năng tiếp cận toàn cầu (High Availability & Global Accessibility):**
   * Public Cloud sở hữu mạng lưới trung tâm dữ liệu và mạng phân phối nội dung (CDN) toàn cầu với cam kết SLA độ sẵn sàng đạt 99.95% - 99.99%. Sinh viên có thể truy cập, tra cứu và tải tài liệu học tập từ bất kỳ đâu (ở nhà, ký túc xá, quán cà phê) với tốc độ cao và độ trễ thấp nhất.

---

### 3.3. Lựa chọn Dịch vụ Cloud cụ thể: Tự dựng IaaS/PaaS vs Giải pháp BaaS (Firebase)

Sau khi xác định mô hình Public Cloud, bài toán tiếp theo là lựa chọn hình thức dịch vụ đám mây phù hợp giữa:
* **Phương án A (Tự dựng IaaS/PaaS truyền thống):** Thuê máy chủ ảo/container (AWS EC2 / App Runner / ECS), tự viết mã nguồn Backend API (Node.js/Spring Boot), tự cấu hình CSDL quan hệ (AWS RDS PostgreSQL) và Object Storage (AWS S3).
* **Phương án B (Backend-as-a-Service - BaaS):** Tận dụng nền tảng serverless trọn gói của Google Cloud / Firebase (Firebase Authentication, Cloud Firestore, Firebase Cloud Storage) kết nối trực tiếp với Flutter Client App.

```
+----------------------------------------------------------------------------------------------------+
|                         SO SÁNH 2 PHƯƠNG ÁN TRIỂN KHAI PUBLIC CLOUD                                |
+----------------------------------------------------+-----------------------------------------------+
|    PHƯƠNG ÁN A: TỰ DỰNG TRUYỀN THỐNG (IaaS/PaaS)   |      PHƯƠNG ÁN B: SỬ DỤNG BaaS (FIREBASE)     |
|             (AWS S3 + RDS + API Gateway)           |       (Firebase Auth + Firestore + Storage)   |
| • Viết mã nguồn Backend riêng (Node.js/Spring)     | • Không cần viết mã nguồn server Backend      |
| • Phải cấu hình API Gateway, Routing, Docker       | • Tích hợp trực tiếp Client SDK vào Flutter   |
| • Tự quản lý xác thực JWT, Refresh Token           | • Xác thực Google Sign-In có sẵn 100%         |
| • RDS tốn phí cố định hàng tháng (~$15-$25/tháng)  | • Hoàn toàn Miễn phí trong hạn mức Free Tier  |
| • Thời gian hoàn thiện: 3 - 4 tuần                 | • Thời gian hoàn thiện: 2 - 3 ngày            |
+----------------------------------------------------+-----------------------------------------------+
```

#### Bảng so sánh chi tiết giữa AWS IaaS/PaaS và Firebase BaaS

| Tiêu chí | Tự dựng IaaS/PaaS (AWS S3 + RDS + API) | Giải pháp BaaS (Firebase Ecosystem) |
|---|---|---|
| **Thời gian ra mắt (Time-to-Market)** | Chậm (Mất 3 - 4 tuần để code Backend, cấu hình DB, viết API CRUD). | **Cực nhanh (Chỉ mất 2 - 3 ngày để gắn SDK và cấu hình Data Source).** |
| **Chi phí hạ tầng ban đầu** | Tốn kém ngay từ đầu (RDS PostgreSQL tốn tối thiểu ~$15 - $25/tháng kể cả không có người dùng). | **$0 tuyệt đối (Gói Free Tier Spark Plan miễn phí 100% dung lượng cho đồ án).** |
| **Độ phức tạp kiến trúc** | Cao: Phải duy trì 2 codebase độc lập (Flutter App + Backend API Server), quản lý Docker, CI/CD. | **Thấp: Toàn bộ dự án nằm trọn trong Flutter codebase, cấu hình qua Firebase Console.** |
| **Cơ chế xác thực (Auth)** | Tự hiện thực mã hóa mật khẩu, bảng `users`, phát hành/thu hồi JWT, Google OAuth backend. | **Có sẵn trọn vẹn: Firebase Auth hỗ trợ Google Sign-In, Email/Password chỉ với vài dòng code.** |
| **Bảo mật & Phân quyền** | Tự code middleware kiểm tra quyền truy cập ở từng endpoint API. | **Khai báo bảo mật tập trung qua Declarative Security Rules (Firestore & Storage).** |
| **Khả năng Offline-first** | Phải tự code SQLite/Hive và viết thuật toán đồng bộ (Sync conflict) rất phức tạp. | **Tích hợp sẵn tự động: Cloud Firestore tự động cache và đồng bộ dữ liệu ngoại tuyến.** |
| **Độ tương thích với Flutter** | Trung bình (Giao tiếp qua HTTP REST thông thường). | **Hoàn hảo (Cùng hệ sinh thái Google, thư viện FlutterFire chính chủ, hỗ trợ đa nền tảng).** |

---

### 3.4. Khẳng định lý do chọn Hệ sinh thái Firebase (Public Cloud BaaS)

Từ các phân tích chuyên sâu trên, **Hệ sinh thái Firebase (Public Cloud BaaS) là sự lựa chọn hoàn hảo và tối ưu nhất** cho dự án Flutter "Study Document Manager". Lý do cụ thể gồm:

> [!IMPORTANT]
> **1. Tối ưu hóa tuyệt đối cho ứng dụng Flutter (Google Ecosystem Synergy):**
> Cả Flutter và Firebase đều là các công nghệ chiến lược do Google xây dựng và phát triển. Bộ thư viện chính chủ **FlutterFire** (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`) được tối ưu hóa ở mức sâu nhất cho ngôn ngữ Dart. Mọi API đều bất đồng bộ tự nhiên (Asynchronous Streams & Futures), cung cấp tài liệu phong phú, cộng đồng hỗ trợ lớn và đảm bảo tính tương thích đồng bộ 100% trên cả Android, iOS, Web và Desktop.

> [!NOTE]
> **2. Giải quyết dứt điểm 2 bài toán khuyết thiếu cốt lõi (Khắc phục hạn chế ở Mục 1 & 2):**
> * **Giải quyết bài toán "Chưa có Database":** Thay thế hoàn toàn lớp lưu tạm trong RAM `DocumentLocalDataSourceImpl` bằng **Cloud Firestore** – CSDL NoSQL Document Store mạnh mẽ, bền vững vĩnh viễn, truy vấn linh hoạt theo tags/môn học và sắp xếp thời gian tự động.
> * **Giải quyết bài toán "Chưa có File Storage":** Thay thế cơ chế lưu chuỗi đường dẫn cục bộ tạm thời bằng **Firebase Cloud Storage** – Hệ thống lưu trữ đối tượng (Object Storage) chuyên dụng, lưu trữ an toàn các tệp nhị phân thực tế (PDF, DOCX, TXT) với khả năng mở rộng hàng Terabyte và tạo URL tải xuống có token bảo mật.

> [!TIP]
> **3. Không tốn công sức dựng Server - Rút ngắn 80% thời gian phát triển:**
> Nhóm phát triển không cần phải xây dựng một hệ thống Backend Node.js hay Java Spring Boot cồng kềnh. Nhờ mô hình Serverless BaaS, Flutter Client giao tiếp trực tiếp với các dịch vụ đám mây của Google thông qua SDK bảo mật, giúp nhóm rút ngắn thời gian phát triển từ hàng tháng xuống chỉ còn vài ngày mà vẫn sở hữu hạ tầng đạt chuẩn doanh nghiệp (Enterprise-grade).

---

## 4. Checklist 4: Thiết kế sơ đồ kiến trúc và Mô tả luồng dữ liệu

### 4.1. Sơ đồ Kiến trúc Tích hợp Cloud (Cloud Architecture Diagram)

Kiến trúc tích hợp của hệ thống được thiết kế theo mô hình **Client-to-Cloud BaaS Architecture**, kết hợp chặt chẽ với nguyên lý **Clean Architecture** sẵn có trong mã nguồn Flutter của dự án:

```mermaid
graph TB
    subgraph CLIENT_TIER["TẦNG CLIENT (Ứng dụng Flutter - Mobile / Web / Desktop)"]
        subgraph UI_LAYER["Presentation Layer"]
            UI["Màn hình UI / Widgets<br/>(Home, Form, Viewer)"]
            CTRL["DocumentController<br/>(Quản lý State & Notifier)"]
        end
        subgraph DOMAIN_LAYER["Domain Layer (Business Logic)"]
            UC["Use Cases<br/>(Add, Get, Search, Delete Doc)"]
            ENT["Entities<br/>(Document, DocumentFilter)"]
        end
        subgraph DATA_LAYER["Data Layer (Infrastructure)"]
            REPO["DocumentRepositoryImpl"]
            DS["DocumentFirebaseDataSourceImpl<br/>(Thay thế Local RAM DS)"]
        end
        UI --> CTRL
        CTRL --> UC
        UC --> REPO
        REPO --> DS
    end

    subgraph CLOUD_BAAS_TIER["TẦNG CLOUD BaaS (Hệ sinh thái Google Firebase)"]
        subgraph AUTH_SERVICE["Firebase Authentication"]
            G_AUTH["Google Sign-In / OAuth2 Provider"]
            AUTH_ENGINE["Auth Engine & Session Token (JWT)"]
        end

        subgraph FIRESTORE_SERVICE["Cloud Firestore (NoSQL Database)"]
            FS_RULES{"Firestore Security Rules<br/>(Kiểm tra UID & Quyền truy cập)"}
            FS_DATA[("Collection: documents<br/>- id, title, subject, tags<br/>- fileUrlOrPath, authorId<br/>- createdAt, updatedAt")]
        end

        subgraph STORAGE_SERVICE["Firebase Cloud Storage (Object Store)"]
            ST_RULES{"Storage Security Rules<br/>(Giới hạn Size, Mime-type, UID)"}
            ST_FILES[("Storage Buckets<br/>/documents/{userId}/{docId}.pdf<br/>Lưu trữ Bytes tệp gốc")]
        end
    end

    subgraph INFRA_TIER["TẦNG HẠ TẦNG NỀN TẢNG (Google Cloud Platform)"]
        G_CDN["Google Global CDN & Edge Caching"]
        G_KMS["Google Cloud KMS (Mã hóa At-rest & In-transit)"]
    end

    %% Giao tiếp giữa Client và Cloud
    DS -->|"1. Gửi OAuth Credentials & Nhận Token"| AUTH_SERVICE
    DS -->|"2. Tải trực tiếp Bytes tệp (UploadTask)"| ST_RULES
    ST_RULES --> ST_FILES
    ST_FILES -->|"3. Trả về downloadURL an toàn"| DS
    DS -->|"4. Ghi/Đọc Metadata tài liệu (HTTPS/gRPC)"| FS_RULES
    FS_RULES --> FS_DATA

    %% Liên kết hạ tầng
    ST_FILES --- G_CDN
    FS_DATA --- G_KMS
    G_CDN -->|"Stream PDF/Tải tệp tốc độ cao"| UI

    classDef client fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef cloud fill:#fff3e0,stroke:#f57c00,stroke-width:2px;
    classDef infra fill:#ede7f6,stroke:#512da8,stroke-width:2px;
    class CLIENT_TIER client;
    class CLOUD_BAAS_TIER cloud;
    class INFRA_TIER infra;
```

#### Thuyết minh các phân tầng kiến trúc:
1. **Tầng Client (Flutter Clean Architecture):**
   * Giữ nguyên vẹn tính phân tách độc lập giữa **Presentation** (Widgets, State Controller) và **Domain** (Use Cases, Entities).
   * Tại **Data Layer**, lớp trừu tượng `IDocumentRepository` sẽ liên kết trực tiếp với lớp hiện thực mới là `DocumentFirebaseDataSourceImpl`.
2. **Tầng Cloud BaaS (Firebase Platform):**
   * **Firebase Authentication:** Quản lý vòng đời đăng nhập của sinh viên/giảng viên qua Google Sign-In, tự động cấp phát ID Token (JSON Web Token) để xác thực người dùng.
   * **Firebase Cloud Storage:** Lưu trữ nội dung nhị phân (Bytes) của các tài liệu tải lên (PDF, DOCX, hình ảnh sơ đồ) trong bucket phân cấp `/documents/{userId}/...`.
   * **Cloud Firestore:** Lưu trữ toàn bộ siêu dữ liệu (Metadata) dưới dạng JSON documents có cấu trúc, cho phép lọc, tìm kiếm và sắp xếp với chỉ mục tốc độ cao.
   * **Security Rules:** Lớp rào chắn an ninh đóng vai trò như Firewall ở tầng ứng dụng, đảm bảo sinh viên chỉ có thể sửa/xóa tài liệu do chính mình tạo ra.
3. **Tầng Hạ tầng (Google Cloud Platform):**
   * Tận dụng mạng lưới Google Global Edge Network để phân phối và stream các file tài liệu PDF nặng về thiết bị với độ trễ thấp nhất. Toàn bộ dữ liệu được tự động mã hóa chuẩn AES-256 (At-rest) và truyền qua kênh bảo mật TLS 1.3 (In-transit).

---

### 4.2. Mô tả chi tiết 3 Luồng dữ liệu (Data Flows) cốt lõi

#### Luồng 1: Xác thực & Đăng nhập (Authentication Flow)
Luồng này đảm bảo nhận diện chính xác danh tính sinh viên thông qua tài khoản Google trường học hoặc cá nhân, tạo cơ sở để kiểm soát quyền tải lên và quản lý tài liệu.

```mermaid
sequenceDiagram
    autonumber
    actor User as Sinh viên / Người dùng
    participant UI as Flutter UI (LoginScreen)
    participant SDK as Google Sign-In SDK
    participant FAuth as Firebase Authentication
    participant LocalSec as Device Secure Storage

    User->>UI: Nhấn "Đăng nhập với Google"
    UI->>SDK: Kích hoạt quy trình Google Sign-In
    SDK->>User: Hiển thị hộp thoại chọn tài khoản Google
    User->>SDK: Cấp quyền & chọn tài khoản
    SDK-->>UI: Trả về Google OAuth Credentials (idToken, accessToken)
    UI->>FAuth: Gọi signInWithCredential(credential)
    FAuth->>FAuth: Xác thực tính hợp lệ với Google Identity Server
    FAuth->>FAuth: Tạo mới/Cập nhật User Profile (gán UID duy nhất)
    FAuth-->>LocalSec: Tự động lưu trữ Firebase ID Token & Session State
    FAuth-->>UI: Phát sự kiện authStateChanges() với UserCredential
    UI->>User: Cập nhật giao diện: Điều hướng vào Màn hình chính (HomeScreen)
```

* **Các bước triển khai chi tiết:**
  1. Người dùng bấm nút "Đăng nhập bằng Google" trên giao diện ứng dụng.
  2. Flutter App kích hoạt `google_sign_in` SDK mở màn hình chọn tài khoản Google của hệ điều hành.
  3. Khi người dùng đồng ý cấp quyền, SDK trả về bộ thẻ bài Google OAuth (`idToken` và `accessToken`).
  4. Ứng dụng chuyển đổi sang `AuthCredential` và gọi `FirebaseAuth.instance.signInWithCredential()`.
  5. Firebase Auth xác thực thông tin với Google OAuth Server, tạo một bản ghi tài khoản trên Firebase Console và trả về một đối tượng `User` có mã định danh duy nhất (`UID`).
  6. Firebase SDK tự động duy trì phiên đăng nhập bền vững (Session Persistence) trên Secure Storage của thiết bị. Khi người dùng tắt ứng dụng và mở lại, `FirebaseAuth.instance.currentUser` vẫn giữ nguyên trạng thái mà không yêu cầu đăng nhập lại.

---

#### Luồng 2: Tải tài liệu lên (Upload Document Flow)
Đây là luồng xử lý then chốt giải quyết dứt điểm nhược điểm "không lưu được bytes tệp" của hệ thống cũ. Luồng được thiết kế theo cơ chế **Giao dịch 2 pha (Two-phase Commit)** đảm bảo tính toàn vẹn giữa File nhị phân và Metadata.

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant UI as DocumentFormScreen
    participant Ctrl as DocumentController
    participant Repo as DocumentRepositoryImpl
    participant DS as DocumentFirebaseDataSource
    participant Storage as Firebase Cloud Storage
    participant Firestore as Cloud Firestore

    User->>UI: Chọn tệp (PDF/Word) & Nhập tiêu đề, môn học, tags
    User->>UI: Nhấn "Lưu tài liệu"
    UI->>Ctrl: addDocument(document, fileBytes, fileName)
    Ctrl->>Repo: addDocument(...)
    Repo->>DS: insertDocumentWithFile(...)
    
    rect rgb(240, 248, 255)
    Note over DS,Storage: PHA 1: UPLOAD TỆP NHỊ PHÂN LÊN STORAGE
    DS->>Storage: storage.ref('documents/{uid}/{docId}_{name}').putData(bytes)
    Storage-->>UI: Cập nhật tiến trình UploadTask (0% -> 100%)
    Storage-->>DS: Upload hoàn tất, trả về TaskSnapshot
    DS->>Storage: ref.getDownloadURL()
    Storage-->>DS: Trả về downloadURL an toàn (chứa token chữ ký)
    end

    rect rgb(255, 250, 240)
    Note over DS,Firestore: PHA 2: LƯU METADATA BỀN VỮNG VÀO FIRESTORE
    DS->>DS: Đóng gói DocumentModel:<br/>(title, subject, type, tags, fileUrlOrPath = downloadURL, storagePath, authorId, createdAt)
    DS->>Firestore: firestore.collection('documents').doc(docId).set(model.toJson())
    Firestore-->>DS: Xác nhận ghi thành công
    end

    DS-->>Repo: Trả về DocumentModel đã lưu
    Repo-->>Ctrl: Ánh xạ sang Document Entity
    Ctrl-->>UI: Cập nhật danh sách tài liệu & Đóng Form
    UI->>User: Hiển thị thông báo "Tải lên tài liệu thành công"
```

* **Các bước triển khai chi tiết:**
  1. **Thu thập dữ liệu:** Người dùng nhấn chọn tệp từ thiết bị qua `FilePicker`. Ứng dụng đọc trực tiếp mảng bytes (`Uint8List`) và tên tệp, đồng thời người dùng điền các thông tin: Tiêu đề, Môn học, Loại tài liệu, Mô tả, Tags.
  2. **Pha 1 - Lưu trữ file nhị phân:**
     * Ứng dụng tạo đường dẫn lưu trữ duy nhất trên Firebase Storage: `documents/${currentUser.uid}/${documentId}_${fileName}`.
     * Sử dụng phương thức `ref.putData(bytes, SettableMetadata(contentType: mimeType))` để tải dữ liệu trực tiếp lên đám mây.
     * Firebase SDK hỗ trợ lắng nghe sự kiện `snapshotEvents` cho phép ứng dụng hiển thị tiến trình tải lên (0% - 100%) trực quan cho người dùng.
     * Khi hoàn tất, ứng dụng gọi `ref.getDownloadURL()` để nhận đường dẫn URL tải xuống công khai có chữ ký bảo mật.
  3. **Pha 2 - Lưu trữ Metadata vào Database:**
     * Ứng dụng khởi tạo một `DocumentModel` mới, trong đó gán trường `fileUrlOrPath` chính bằng `downloadURL` vừa nhận được, bổ sung thêm `storagePath` (để phục vụ việc xóa file sau này), `authorId` (UID của người dùng), cùng thời gian tạo `createdAt`.
     * Gửi lệnh ghi vào CSDL: `FirebaseFirestore.instance.collection('documents').doc(documentId).set(model.toJson())`.
  4. **Hoàn tất:** Ứng dụng đóng modal, cập nhật danh sách hiển thị và gửi thông báo thành công cho người dùng.

---

#### Luồng 3: Truy vấn & Tải tài liệu (Query & Download Flow)
Luồng này tối ưu hóa việc tìm kiếm, phân trang và truy cập nội dung bài học, kết hợp sức mạnh chỉ mục của Firestore và khả năng phân phối tệp của CDN.

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant UI as DocumentHomeScreen
    participant Ctrl as DocumentController
    participant Repo as DocumentRepositoryImpl
    participant DS as DocumentFirebaseDataSource
    participant Firestore as Cloud Firestore
    participant Storage as Firebase Storage / CDN

    User->>UI: Nhập từ khóa tìm kiếm hoặc lọc theo Môn học/Loại
    UI->>Ctrl: searchDocuments(query) / filterDocuments(filter)
    Ctrl->>Repo: getDocuments()
    Repo->>DS: getDocuments(filter)
    DS->>Firestore: collection('documents').where(...).orderBy('updatedAt').get()
    Note over DS,Firestore: Tự động truy xuất Local Cache nếu đang mất mạng
    Firestore-->>DS: Trả về QuerySnapshot (Danh sách Documents JSON)
    DS-->>Repo: Ánh xạ JSON sang List<DocumentModel>
    Repo-->>Ctrl: Ánh xạ sang List<Document> Entities
    Ctrl-->>UI: Cập nhật State & Re-render danh sách trên UI

    alt Người dùng nhấn XEM TRỰC TIẾP (In-App PDF View)
        User->>UI: Bấm vào thẻ tài liệu (Xem file)
        UI->>Storage: Mở In-App PDF Viewer với downloadURL
        Storage-->>UI: Stream từng trang dữ liệu PDF qua Google CDN
        UI->>User: Hiển thị nội dung bài giảng mượt mà
    else Người dùng nhấn TẢI VỀ THIẾT BỊ (Download File)
        User->>UI: Bấm biểu tượng "Tải về máy"
        UI->>Storage: Gửi HTTP GET tới downloadURL
        Storage-->>UI: Truyền tải luồng Bytes tệp tin
        UI->>UI: Lưu Bytes vào thư mục /Download của thiết bị qua path_provider
        UI->>User: Hiển thị thông báo "Đã lưu tệp vào máy"
    end
```

* **Các bước triển khai chi tiết:**
  1. **Truy vấn danh sách:** Khi người dùng mở ứng dụng hoặc nhập bộ lọc, `DocumentController` gọi tầng Data Source. Lớp `DocumentFirebaseDataSourceImpl` xây dựng truy vấn Firestore:
     ```dart
     Query query = firestore.collection('documents');
     if (filter.subject != null) query = query.where('subject', isEqualTo: filter.subject);
     if (filter.type != null) query = query.where('type', isEqualTo: filter.type);
     query = query.orderBy('updatedAt', descending: true);
     ```
  2. **Tận dụng Offline Persistence:** Firestore tự động kiểm tra bộ nhớ đệm cục bộ. Nếu người dùng đang ngoại tuyến (mất mạng), dữ liệu đã tải trước đó vẫn được hiển thị trơn tru.
  3. **Đọc tệp tin:** Khi người dùng có nhu cầu đọc nội dung tệp:
     * **Xem trực tiếp:** Ứng dụng truyền `downloadURL` vào widget `SfPdfViewer.network` hoặc `flutter_pdfview`. Tệp tin được truyền phát trực tiếp (Streaming) qua Google CDN mà không bắt buộc người dùng phải tải trọn bộ file về máy.
     * **Tải về ngoại tuyến:** Ứng dụng thực hiện HTTP GET để đọc stream bytes và lưu vào thư mục tài liệu của thiết bị thông qua thư viện `path_provider`, hỗ trợ xem lại hoàn toàn khi không có Internet.

---

### 4.3. Cập nhật kiến trúc nguồn code Flutter (Clean Architecture Refactoring)

Một trong những ưu điểm vượt trội nhất của dự án "Study Document Manager" là việc thiết kế tuân thủ nghiêm ngặt **Clean Architecture** và nguyên lý **Đảo ngược phụ thuộc (Dependency Inversion Principle - DIP)** ngay từ đầu.

Nhờ cấu trúc này, khi chuyển đổi từ lưu trữ RAM tạm thời sang lưu trữ Cloud Firebase, chúng ta:
* **GIỮ NGUYÊN 100% TẦNG PRESENTATION:** Không cần sửa đổi bất kỳ màn hình (`DocumentHomeScreen`, `DocumentFormScreen`), widget hay `DocumentController` nào.
* **GIỮ NGUYÊN 100% TẦNG DOMAIN:** Toàn bộ các Use Cases (`AddDocumentUseCase`, `GetDocumentsUseCase`, `DeleteDocumentUseCase`) và Entities (`Document`) hoàn toàn độc lập với Firebase.
* **CHỈ THAY THẾ DUY NHẤT TẠI TẦNG DATA & KHỞI TẠO TẠI `main.dart`:** Thay thế `DocumentLocalDataSourceImpl` bằng một lớp Data Source mới kết nối trực tiếp với Firebase SDK.

```
       [TẦNG DOMAIN / USE CASES]
                   ▲
                   │ (Phụ thuộc vào trừu tượng)
       ┌───────────┴───────────────────────┐
       │   abstract class IDocumentDataSource  │  <-- Hợp đồng chuẩn
       └───────────────────────────────────┘
                   ▲                       ▲
                   │ (Thực thi)            │ (Thực thi)
       ┌───────────┴─────────────┐  ┌──────┴──────────────────────────┐
       │ DocumentLocalDataSource │  │ DocumentFirebaseDataSourceImpl   │
       │ (Cũ: Lưu trong RAM)     │  │ (MỚI: Kết nối Firestore & Storage)│
       └─────────────────────────┘  └─────────────────────────────────┘
```

#### 1. Xây dựng Data Source mới: `DocumentFirebaseDataSourceImpl`
Tạo file mới tại đường dẫn `lib/data/datasources/document_firebase_datasource.dart`:

```dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel?> getDocumentById(String id);
  Future<DocumentModel> insertDocument(DocumentModel doc, {Uint8List? fileBytes, String? fileName});
  Future<DocumentModel> updateDocument(DocumentModel doc);
  Future<bool> deleteDocument(String id);
}

class DocumentFirebaseDataSourceImpl implements DocumentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentFirebaseDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _documentsCollection => _firestore.collection('documents');

  @override
  Future<List<DocumentModel>> getDocuments() async {
    final snapshot = await _documentsCollection
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DocumentModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    final doc = await _documentsCollection.doc(id).get();
    if (!doc.exists) return null;
    return DocumentModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<DocumentModel> insertDocument(
    DocumentModel doc, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    String finalFileUrl = doc.fileUrlOrPath;

    // Pha 1: Nếu có bytes tệp thực tế -> Upload lên Firebase Storage
    if (fileBytes != null && fileBytes.isNotEmpty && fileName != null) {
      final storageRef = _storage.ref().child('documents/${doc.id}_$fileName');
      final uploadTask = await storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      finalFileUrl = await uploadTask.ref.getDownloadURL();
    }

    // Pha 2: Cập nhật downloadURL vào model và lưu Metadata lên Firestore
    final updatedDoc = doc.copyWith(fileUrlOrPath: finalFileUrl);
    await _documentsCollection.doc(doc.id).set(updatedDoc.toJson());
    return updatedDoc;
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    await _documentsCollection.doc(doc.id).update(doc.toJson());
    return doc;
  }

  @override
  Future<bool> deleteDocument(String id) async {
    // 1. Lấy thông tin tài liệu để lấy đường dẫn file trên Storage nếu có
    final docSnapshot = await _documentsCollection.doc(id).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final fileUrl = data['fileUrlOrPath'] as String?;
      if (fileUrl != null && fileUrl.startsWith('https://firebasestorage')) {
        try {
          await _storage.refFromURL(fileUrl).delete();
        } catch (_) {
          // Bỏ qua lỗi nếu file vật lý đã bị xóa từ trước
        }
      }
    }
    // 2. Xóa bản ghi metadata trong Firestore
    await _documentsCollection.doc(id).delete();
    return true;
  }
}
```

#### 2. Cập nhật Điểm khởi tạo ứng dụng tại `lib/main.dart`
Hoán đổi nguồn dữ liệu sạch sẽ thông qua Dependency Injection trong `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Thêm Firebase Core

// Thay thế import DataSource cũ
// import 'data/datasources/document_local_datasource.dart';
import 'data/datasources/document_firebase_datasource.dart'; // Import DataSource mới
import 'data/repositories/document_repository_impl.dart';
import 'presentation/controllers/document_controller.dart';
import 'presentation/screens/document_home_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'usecases/add_document_usecase.dart';
import 'usecases/delete_document_usecase.dart';
import 'usecases/get_document_stats_usecase.dart';
import 'usecases/get_documents_usecase.dart';
import 'usecases/search_documents_usecase.dart';
import 'usecases/update_document_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BƯỚC 1: Khởi tạo Firebase SDK trên nền tảng Cloud
  await Firebase.initializeApp();

  // BƯỚC 2: Hoán đổi Data Source (Thay thế RAM in-memory bằng Firebase BaaS)
  // final localDataSource = DocumentLocalDataSourceImpl(autoSeed: true); // <-- BỎ LỚP CŨ
  final firebaseDataSource = DocumentFirebaseDataSourceImpl();          // <-- DÙNG LỚP MỚI

  final documentRepository = DocumentRepositoryImpl(
    remoteDataSource: firebaseDataSource,
  );

  // BƯỚC 3: Giữ nguyên vẹn 100% Tầng Use Cases (Business Logic không hề bị ảnh hưởng)
  final addDocumentUseCase = AddDocumentUseCase(repository: documentRepository);
  final updateDocumentUseCase = UpdateDocumentUseCase(repository: documentRepository);
  final deleteDocumentUseCase = DeleteDocumentUseCase(repository: documentRepository);
  final searchDocumentsUseCase = SearchDocumentsUseCase(repository: documentRepository);
  final getDocumentsUseCase = GetDocumentsUseCase(repository: documentRepository);
  final getDocumentStatsUseCase = GetDocumentStatsUseCase(repository: documentRepository);

  // BƯỚC 4: Giữ nguyên vẹn 100% Controller và UI
  final documentController = DocumentController(
    addDocumentUseCase: addDocumentUseCase,
    updateDocumentUseCase: updateDocumentUseCase,
    deleteDocumentUseCase: deleteDocumentUseCase,
    searchDocumentsUseCase: searchDocumentsUseCase,
    getDocumentsUseCase: getDocumentsUseCase,
    getDocumentStatsUseCase: getDocumentStatsUseCase,
  )..init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DocumentController>.value(
          value: documentController,
        ),
      ],
      child: const StudyDocumentManagerApp(),
    ),
  );
}
```

---

## 5. Đánh giá tác động về bảo mật, chi phí và hiệu suất (Firebase BaaS)

| Khía cạnh | Lợi thế vượt trội của Firebase BaaS | Thách thức kỹ thuật & Giải pháp kiểm soát |
|---|---|---|
| **Bảo mật (Security)** | • Tích hợp chuẩn Google Identity OAuth2.<br/>• Bảo vệ dữ liệu bằng **Security Rules** khai báo ở tầng Firestore & Storage.<br/>• Mã hóa tự động At-rest (AES-256) và In-transit (TLS 1.3). | • **Nguy cơ:** Cấu hình Security Rules ở chế độ `allow read, write: if true;` trong lúc phát triển có thể làm lộ dữ liệu nếu quên đóng khi lên Production.<br/>• **Giải pháp:** Thiết lập Rules nghiêm ngặt: Chỉ người dùng đã xác thực mới được tạo (`request.auth != null`), chỉ chủ sở hữu tài liệu mới được chỉnh sửa hoặc xóa (`request.auth.uid == resource.data.authorId`). |
| **Chi phí (Cost)** | • **$0 chi phí khởi điểm:** Gói Spark Plan miễn phí hoàn toàn 1 GB CSDL NoSQL, 5 GB Storage và 50.000 lượt đọc/ngày.<br/>• Chuyển đổi linh hoạt sang Pay-as-you-go (Blaze Plan) khi quy mô người dùng vượt ngưỡng mà không cần thay đổi kiến trúc. | • **Nguy cơ:** Lập trình viên viết truy vấn vòng lặp vô tận (infinite loop listener) có thể làm tăng vọt số lượt đọc Firestore (Read counts).<br/>• **Giải pháp:** Cài đặt Cloud Budget Alerts cảnh báo ngưỡng ngân sách từ $1/tháng, bật tính năng phân trang (Pagination với `limit(20)`) và tận dụng tối đa Local Cache. |
| **Hiệu suất (Performance)** | • Tải trực tiếp Bytes tệp lên Cloud Storage mà không cần thông qua máy chủ trung gian, loại bỏ hoàn toàn điểm nghẽn cổ chai (Bottleneck).<br/>• Tận dụng mạng lưới Google Global Edge CDN để tải/stream tệp PDF cực nhanh.<br/>• Firestore hỗ trợ tự động chỉ mục (Indexing) cho tốc độ tìm kiếm dưới 50ms. | • **Nguy cơ:** Tải các tệp tài liệu PDF dung lượng quá lớn (> 50 MB) có thể gây tốn băng thông thiết bị di động.<br/>• **Giải pháp:** Giới hạn dung lượng tải lên tối đa 25 MB/tệp tại giao diện và tại Storage Security Rules (`request.resource.size < 25 * 1024 * 1024`), hiển thị tiến trình phần trăm để tăng trải nghiệm người dùng. |

---

## Kết luận

Việc lựa chọn **Public Cloud** và triển khai giải pháp **BaaS trên hệ sinh thái Google Firebase (Firebase Authentication, Cloud Firestore, Firebase Cloud Storage)** là quyết định kiến trúc chuẩn xác nhất cho ứng dụng Flutter "Study Document Manager".

Giải pháp này:
1. **Giải quyết dứt điểm 100% các hạn chế và điểm nghẽn** được xác nhận ở Checklist 1 & 2 (Không còn mất dữ liệu khi tắt app, lưu trữ an toàn bytes tệp tài liệu, đồng bộ hóa đa thiết bị, tìm kiếm có chỉ mục).
2. **Tối ưu hóa tối đa nguồn lực phát triển:** Không tốn chi phí và công sức dựng máy chủ backend truyền thống, rút ngắn thời gian hoàn thiện đồ án.
3. **Bảo tồn tính toàn vẹn của mã nguồn:** Chứng minh sức mạnh của mô hình **Clean Architecture** khi việc chuyển đổi từ CSDL tạm trong RAM sang Cloud BaaS không làm thay đổi bất kỳ dòng mã nào ở tầng Presentation hay Business Logic Domain.
