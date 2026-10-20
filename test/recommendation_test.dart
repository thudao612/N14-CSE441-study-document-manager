import 'package:flutter_test/flutter_test.dart';
// Tự động liên kết đến file thuật toán bạn làm ở Bước 1
import 'package:my_first_app/document_recommendation.dart';

void main() {
  group('Kiểm thử hệ thống thuật toán gợi ý tài liệu học tập (CL5)', () {
    
    // 1. Kho dữ liệu giả lập để chạy thử nghiệm
    final List<Map<String, dynamic>> mockDatabase = [
      {'id': '1', 'title': 'Giáo trình Toán Cao Cấp A1', 'tags': ['Toán', 'Đại số']},
      {'id': '2', 'title': 'Lập trình Flutter căn bản', 'tags': ['Mobile', 'Flutter', 'Dart']},
      {'id': '3', 'title': 'Giải tích 1 nâng cao', 'tags': ['Toán', 'Giải tích']},
      {'id': '4', 'title': 'Cấu trúc dữ liệu và Giải thuật', 'tags': ['IT', 'Thuật toán']},
      {'id': '5', 'title': 'Thiết kế giao diện với Figma', 'tags': ['Mobile', 'UI', 'UX']},
    ];

    // 2. Kịch bản test 1: Kiểm tra công thức tính điểm Jaccard
    test('Test 1: Điểm Jaccard phải bằng 1.0 khi trùng khớp hoàn toàn danh sách Tag', () {
      double score = DocumentRecommendation.calculateJaccardScore(
        ['Toán', 'Đại số'], 
        ['Toán', 'Đại số']
      );
      expect(score, 1.0); 
    });

    // 3. Kịch bản test 2: Lọc top 5 và sắp xếp giảm dần theo độ liên quan
    test('Test 2: Hệ thống phải lọc đúng tài liệu liên quan và sắp xếp giảm dần', () {
      List<String> userInterests = ['Toán']; // Người dùng thích chủ đề Toán
      
      var results = DocumentRecommendation.getTopRecommendations(
        allDocuments: mockDatabase, 
        userPreferredTags: userInterests
      );

      // Thỏa mãn đầu mục 2: Danh sách gợi ý không được vượt quá 5 tài liệu
      expect(results.length, lessThanOrEqualTo(5));
      
      // Tài liệu ID 1 (Toán Cao Cấp) phải được xếp lên đầu vì độ tương đồng cao nhất
      expect(results.first['id'], '1');
      
      // Tài liệu ID 2 (Flutter) không được xuất hiện vì không trùng tag nào
      expect(results.any((doc) => doc['id'] == '2'), isFalse);
    });
  });
}
