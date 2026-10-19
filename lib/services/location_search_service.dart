import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  final String displayName;
  final LatLng location;

  const LocationSearchResult({
    required this.displayName,
    required this.location,
  });

  factory LocationSearchResult.fromPhotonFeature(
    Map<String, dynamic> feature,
  ) {
    final coordinates =
        (feature['geometry'] as Map<String, dynamic>?)?['coordinates'];
    final properties = feature['properties'] as Map<String, dynamic>?;
    final longitude = coordinates is List && coordinates.length >= 2
        ? double.tryParse(coordinates[0].toString())
        : null;
    final latitude = coordinates is List && coordinates.length >= 2
        ? double.tryParse(coordinates[1].toString())
        : null;
    final displayName = _formatPhotonName(properties);

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        displayName.isEmpty) {
      throw const FormatException(
          'Dữ liệu địa điểm từ dịch vụ tìm kiếm không hợp lệ.');
    }

    return LocationSearchResult(
      displayName: displayName,
      location: LatLng(latitude, longitude),
    );
  }
}

String _formatPhotonName(Map<String, dynamic>? properties) {
  if (properties == null) return '';

  final name = properties['name']?.toString().trim() ?? '';
  final locality = properties['locality']?.toString().trim() ?? '';
  final district = properties['district']?.toString().trim() ?? '';
  final city = properties['city']?.toString().trim() ?? '';
  final country = properties['country']?.toString().trim() ?? '';
  final parts = <String>[];
  for (final part in [name, locality, district, city, country]) {
    if (part.isNotEmpty && !parts.contains(part)) parts.add(part);
  }
  return parts.join(', ');
}

class LocationSearchService {
  LocationSearchService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  DateTime? _lastRequestAt;

  Future<List<LocationSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final elapsed = DateTime.now().difference(lastRequestAt);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();

    final response = await _dio.get<Map<String, dynamic>>(
      'https://photon.komoot.io/api/',
      queryParameters: {
        'q': trimmedQuery,
        'limit': 6,
        'lang': 'en',
        'lat': 21.0077,
        'lon': 105.8264,
      },
      options: Options(
        // The Photon API is CORS-enabled; avoid custom headers on web.
        headers: kIsWeb
            ? null
            : const {
                'Accept': 'application/json',
                'User-Agent':
                    'StudyDocumentManager/1.0 (Flutter map place search)',
              },
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Dịch vụ tìm kiếm không trả về dữ liệu.');
    }
    final features = data['features'];
    if (features is! List) {
      throw const FormatException(
        'Phản hồi tìm kiếm không đúng định dạng GeoJSON.',
      );
    }

    return features
        .whereType<Map<String, dynamic>>()
        .map(LocationSearchResult.fromPhotonFeature)
        .toList();
  }
}
