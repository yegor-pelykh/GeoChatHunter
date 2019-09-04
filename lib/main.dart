import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'restricted_data.dart' as RestrictedData;

void main() => runApp(GeoChatHunterApp());

class GeoChatHunterApp extends StatefulWidget {
  const GeoChatHunterApp({Key key}) : super(key: key);

  @override
  _GeoChatHunterAppState createState() => _GeoChatHunterAppState();
}

class _GeoChatHunterAppState extends State<GeoChatHunterApp>
    with SingleTickerProviderStateMixin {
  final List<Tab> _tabs = [
    Tab(text: 'Map', icon: Icon(Icons.map)),
    Tab(text: 'GeoChats', icon: Icon(Icons.view_list))
  ];
  final LatLng _startingCenter = LatLng(51.5, -0.09);

  TabController _tabController;
  MapController _mapController;
  LatLng _centerLocation;
  LatLng _markerLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabs.length);
    _mapController = MapController();
    _markerLocation = _startingCenter;
    _centerLocation = _startingCenter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoChat Hunter',
      home: Scaffold(
        appBar: AppBar(
            title: const Text('GeoChat Hunter'),
            bottom: TabBar(controller: _tabController, tabs: _tabs)),
        body: TabBarView(
          controller: _tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    _centerLocation = position.center;
                  },
                  onTap: (LatLng location) {
                    setState(() {
                      _markerLocation = location;
                    });
                  },
                  center: _centerLocation,
                  zoom: 13.0),
              layers: [
                TileLayerOptions(
                    urlTemplate: RestrictedData.urlTemplate,
                    additionalOptions: RestrictedData.additionalOptions
                ),
                MarkerLayerOptions(markers: [
                  Marker(
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                      width: 50.0,
                      height: 50.0,
                      point: _markerLocation,
                      builder: (ctx) => Container(
                          child: Icon(Icons.location_on,
                              color: Colors.red, size: 50)))
                ]),
              ],
            ),
            Icon(Icons.view_list)
          ],
        ),
      ),
    );
  }
}
