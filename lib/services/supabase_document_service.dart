import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../data/models/document_model.dart';
import '../domain/entities/document.dart';

class SupabaseDocumentService {
  SupabaseDocumentService();

  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  Future<void> initialize() async {
    _isConfigured = SupabaseConfig.isConfigured;
  }

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    if (!_isConfigured) {
      return [
        {
          'id': 'doc-demo-1',
          'title': 'README.md',
          'subject': 'General',
          'description':
              'Demo document metadata from Supabase-ready configuration.',
        },
      ];
    }

    try {
      final response =
          await Supabase.instance.client.from('documents').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDocument(Document document) async {
    if (!_isConfigured) {
      throw StateError('Supabase chưa được cấu hình.');
    }

    final documentData = DocumentModel.fromEntity(document).toSupabaseJson();
    await Supabase.instance.client.from('documents').upsert(documentData);
  }

  Future<List<Map<String, dynamic>>> fetchPermissions() async {
    if (!_isConfigured) {
      return [
        {
          'document_id': 'doc-demo-1',
          'user_id': 'demo-user',
          'level': 'owner',
        },
      ];
    }

    try {
      final response =
          await Supabase.instance.client.from('document_permissions').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<bool> shareDocument({
    required String documentId,
    required String userId,
    required String level,
  }) async {
    if (!_isConfigured) {
      return true;
    }

    try {
      await Supabase.instance.client.from('document_permissions').insert({
        'document_id': documentId,
        'user_id': userId,
        'level': level,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
