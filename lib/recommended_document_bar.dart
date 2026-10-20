import 'package:flutter/material.dart';

class RecommendedDocumentBar extends StatelessWidget {
  final List<Map<String, dynamic>> recommendedDocs;
  final List<Map<String, dynamic>> latestDocs;

  const RecommendedDocumentBar({
    super.key,
    required this.recommendedDocs,
    required this.latestDocs,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRecommendations = recommendedDocs.isNotEmpty;
    final List<Map<String, dynamic>> displayDocs = hasRecommendations 
        ? recommendedDocs 
        : latestDocs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            hasRecommendations ? '🔥 Gợi ý dành cho bạn' : '✨ Tài liệu học tập mới nhất',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        SizedBox(
          height: 170,
          child: displayDocs.isEmpty
              ? const Center(
                  child: Text('Hiện tại không có tài liệu nào phù hợp.', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: displayDocs.length,
                  itemBuilder: (context, index) {
                    final doc = displayDocs[index];
                    return Container(
                      width: 135,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 85,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.menu_book_rounded, size: 36, color: Colors.blue),
                                ),
                              ),
                              Padding(
padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  doc['title'] ?? 'Tài liệu không tên',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}