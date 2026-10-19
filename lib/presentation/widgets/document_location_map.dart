import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DocumentLocationMap extends StatelessWidget {
  final LatLng center;
  final LatLng? marker;
  final ValueChanged<LatLng>? onTap;
  final double zoom;
  final MapController? mapController;

  const DocumentLocationMap({
    super.key,
    required this.center,
    this.marker,
    this.onTap,
    this.zoom = 15,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.studymanager.study_document_manager',
          errorTileCallback: (_, error, __) {
            debugPrint('Unable to load map tile from OpenStreetMap: $error');
          },
        ),
        if (marker != null)
          MarkerLayer(
            markers: [
              Marker(
                point: marker!,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
