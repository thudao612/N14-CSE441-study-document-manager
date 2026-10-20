class DocumentRecommendation {
  /// 1. Hàm tính điểm tương đồng Jaccard giữa danh sách Tag của tài liệu và Tag user thích
  static double calculateJaccardScore(List<String> documentTags, List<String> userPreferredTags) {
    if (documentTags.isEmpty || userPreferredTags.isEmpty) return 0.0;

    // Chuyển danh sách về Set để thực hiện các phép toán tập hợp (loại bỏ trùng lặp, viết thường, xóa khoảng cách thừa)
    var docSet = documentTags.map((e) => e.toLowerCase().trim()).toSet();
    var userSet = userPreferredTags.map((e) => e.toLowerCase().trim()).toSet();

    // Tìm tập giao (đếm xem có bao nhiêu tag giống nhau giữa 2 bên)
    var intersection = docSet.intersection(userSet).length;

    // Tìm tập hợp (tổng số lượng các tag khác biệt gộp lại)
    var union = docSet.union(userSet).length;

    if (union == 0) return 0.0;
    return intersection / union; // Điểm số trả về chạy từ 0.0 đến 1.0
  }

  /// 2. Hàm lọc và sắp xếp để chọn ra tối đa 5 tài liệu có độ tương đồng cao nhất
  static List<Map<String, dynamic>> getTopRecommendations({
    required List<Map<String, dynamic>> allDocuments,
    required List<String> userPreferredTags,
  }) {
    List<Map<String, dynamic>> scoredDocuments = [];

    // Duyệt qua từng tài liệu có trong kho dữ liệu
    for (var doc in allDocuments) {
      List<String> docTags = List<String>.from(doc['tags'] ?? []);
      double score = calculateJaccardScore(docTags, userPreferredTags);
      
      // Chỉ giữ lại những tài liệu có điểm tương đồng lớn hơn 0
      if (score > 0) {
        var scoredDoc = Map<String, dynamic>.from(doc);
        scoredDoc['recommendationScore'] = score; // Đính kèm điểm số vào dữ liệu tài liệu
        scoredDocuments.add(scoredDoc);
      }
    }

    // Sắp xếp giảm dần theo điểm số (Tài liệu nào điểm cao hơn, phù hợp hơn xếp lên trước)
    scoredDocuments.sort((a, b) => b['recommendationScore'].compareTo(a['recommendationScore']));

    // Trả về tối đa 5 tài liệu đứng đầu danh sách (Đầu mục 2)
    return scoredDocuments.take(5).toList();
  }
}