import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/services/location_search_service.dart';

void main() {
  group('LocationSearchResult', () {
    test('parses Photon GeoJSON coordinates and Vietnamese place names', () {
      final result = LocationSearchResult.fromPhotonFeature({
        'geometry': {
          'type': 'Point',
          'coordinates': [105.7998712, 20.9841617],
        },
        'properties': {
          'name': 'Phố Triều Khúc',
          'district': 'Thanh Liet Ward',
          'city': 'Hanoi',
          'country': 'Vietnam',
        },
      });

      expect(
        result.displayName,
        'Phố Triều Khúc, Thanh Liet Ward, Hanoi, Vietnam',
      );
      expect(result.location.latitude, 20.9841617);
      expect(result.location.longitude, 105.7998712);
    });

    test('rejects malformed coordinates from the geocoding response', () {
      expect(
        () => LocationSearchResult.fromPhotonFeature({
          'geometry': {
            'type': 'Point',
            'coordinates': [105.854444, 91],
          },
          'properties': {'name': 'Invalid place'},
        }),
        throwsFormatException,
      );
    });
  });
}
