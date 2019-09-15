import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';
import 'package:geochat_hunter/restricted_access_data.dart' as RestrictedAccessData;
import 'package:geochat_hunter/position_controller.dart';

final LatLng startPosition = LatLng(0, 0);
final double startZoom = 12.0;
final double markerSize = 50.0;

class MapTab extends StatefulWidget {
    MapTab({Key key}) : super(key: key);

    @override
    _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
    Location _location;
    MapController _mapController;
    LatLng _centerPosition;
    double _zoomFactor;
    LatLng _markerPosition;

    _MapTabState() {
        _centerPosition = startPosition;
        _zoomFactor = startZoom;
        _markerPosition = startPosition;
        _location = Location();
        _mapController = MapController();
    }

    @override
    void initState() {
        super.initState();
        _moveToDeviceLocation();
    }

    Future _moveToDeviceLocation() async {
        try {
            LocationData data = await _location.getLocation();
            LatLng position = LatLng(data.latitude, data.longitude);
            if (_mapController.ready) {
                _mapController.move(position, _mapController.zoom);
            } else {
                setState(() {
                    _centerPosition = position;
                });
            }
            _setMarkerPosition(position);
        } on Exception catch (e) {
            print(e);
        }
    }

    @override
    Widget build(BuildContext context) {
        return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                onPositionChanged: (MapPosition position, bool hasGesture) {
                    _centerPosition = position.center;
                    _zoomFactor = position.zoom;
                },
                onTap: (LatLng position) {
                    _setMarkerPosition(position);
                },
                center: _centerPosition,
                zoom: _zoomFactor
            ),
            layers: [
                TileLayerOptions(
                    urlTemplate: RestrictedAccessData.mapUrlTemplate,
                    additionalOptions: RestrictedAccessData.mapAdditionalOptions),
                MarkerLayerOptions(markers: [
                    Marker(
                        anchorPos: AnchorPos.align(AnchorAlign.top),
                        width: markerSize,
                        height: markerSize,
                        point: _markerPosition,
                        builder: (ctx) => Container(
                            child: Icon(Icons.location_on,
                                color: Colors.red, size: markerSize)))
                ])
            ]
        );
    }

    void _setMarkerPosition(LatLng position) {
        setState(() {
            _markerPosition = position;
        });
        PositionController().setNewPosition(position);
    }

    @override
    void dispose() {
        super.dispose();
    }

}
