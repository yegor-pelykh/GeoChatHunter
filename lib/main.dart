import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'restricted_data.dart' as RestrictedData;
import 'telegram_controller.dart';

final String appTitle = 'GeoChat Hunter';
final LatLng startPosition = LatLng(0, 0);
final double startZoom = 12.0;
final List<Tab> tabs = [
    Tab(text: 'Map', icon: Icon(Icons.map)),
    Tab(text: 'GeoChats', icon: Icon(Icons.view_list))
];

void main() => runApp(GeoChatHunterApp());

class GeoChatHunterApp extends StatefulWidget {
    const GeoChatHunterApp({Key key}) : super(key: key);

    @override
    _GeoChatHunterAppState createState() => _GeoChatHunterAppState();
}

class _GeoChatHunterAppState extends State<GeoChatHunterApp> with TickerProviderStateMixin {
    PackageInfo _packageInfo;
    Location _location;
    TelegramController _telegramController;
    TabController _tabController;
    MapController _mapController;
    LatLng _centerPosition;
    double _zoomFactor;
    LatLng _markerPosition;
    AuthorizationState _authorizationState;

    _GeoChatHunterAppState() {
        _centerPosition = startPosition;
        _zoomFactor = startZoom;
        _markerPosition = startPosition;
        _initLocationModule();
        _initMapController();
        _initTabController();
    }

    void _initLocationModule() {
        _location = Location();
    }

    void _initMapController() {
        _mapController = MapController();
    }

    void _initTabController() {
        _tabController = TabController(vsync: this, length: tabs.length);
    }

    @override
    void initState() {
        super.initState();
        _initPackageInfoModule().then((void _) {
            _initTelegramController();
            _moveToDeviceLocation();
        });
    }

    Future<void> _initPackageInfoModule() async {
        _packageInfo = await PackageInfo.fromPlatform();
    }

    void _initTelegramController() {
        _telegramController = TelegramController(
            appVersion: _packageInfo.version,
            authorizationStateChanged: _onTelegramAuthorizationStateChanged
        );
    }

    Future<void> _moveToDeviceLocation() async {
        try {
            LocationData data = await _location.getLocation();
            LatLng position = LatLng(data.latitude, data.longitude);
            setState(() {
                if (_mapController.ready) {
                    _mapController.move(position, _mapController.zoom);
                } else {
                    _centerPosition = position;
                }
                _setMarkerPosition(position);
            });
        } on Exception {}
    }

    void _onTelegramAuthorizationStateChanged(AuthorizationState state) {
        setState(() {
            _authorizationState = state;
        });
    }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: appTitle,
            home: getHomePage(context)
        );
    }

    void _setMarkerPosition(LatLng position) {
        _markerPosition = position;
    }

    Widget getProcessingPage(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(appTitle)
            ),
            backgroundColor: Colors.blue,
            body: SpinKitRipple(
                color: Colors.white,
                size: 100.0
            )
        );
    }

    Widget getLoginPage(BuildContext context) {
        return Scaffold();
    }

    Widget getMainPage(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(appTitle),
                bottom: TabBar(controller: _tabController, tabs: tabs)),
            body: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                    FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                            onPositionChanged: (MapPosition position, bool hasGesture) {
                                _centerPosition = position.center;
                                _zoomFactor = position.zoom;
                            },
                            onTap: (LatLng location) {
                                setState(() {
                                    _setMarkerPosition(location);
                                });
                            },
                            center: _centerPosition,
                            zoom: _zoomFactor
                        ),
                        layers: [
                            TileLayerOptions(
                                urlTemplate: RestrictedData.mapUrlTemplate,
                                additionalOptions: RestrictedData.mapAdditionalOptions),
                            MarkerLayerOptions(markers: [
                                Marker(
                                    anchorPos: AnchorPos.align(AnchorAlign.top),
                                    width: 50.0,
                                    height: 50.0,
                                    point: _markerPosition,
                                    builder: (ctx) => Container(
                                        child: Icon(Icons.location_on,
                                            color: Colors.red, size: 50)))
                            ]),
                        ],
                    ),
                    Icon(Icons.view_list)
                ],
            ),
        );
    }

    Widget getHomePage(BuildContext context) {
        switch (_authorizationState) {
            case AuthorizationState.infoNeeded:
                return getLoginPage(context);
            case AuthorizationState.ready:
                return getMainPage(context);
            case AuthorizationState.processing: default:
                return getProcessingPage(context);
        }
    }

    @override
    void dispose() {
        _tabController.dispose();
        _telegramController.dispose();
        super.dispose();
    }

}
