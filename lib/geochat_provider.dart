import 'dart:async';
import 'package:latlong/latlong.dart';
import 'package:geochat_hunter/telegram_controller.dart';
import 'package:geochat_hunter/position_controller.dart';

final int searchRadius = 1000;
final int searchLimit = 100;

class GeochatProvider {
    // Singleton implementation
    static final GeochatProvider _instance = GeochatProvider._internal();
    factory GeochatProvider() => _instance;

    // Internal fields
    StreamController<List<dynamic>> _geochatListStreamController;
    StreamSubscription<LatLng> _positionStreamSubscription;

    GeochatProvider._internal() {
        _geochatListStreamController = StreamController.broadcast();
        _subscribeToPositionChanging();
    }

    _subscribeToPositionChanging() {
        if (_positionStreamSubscription != null)
            return;

        _positionStreamSubscription = PositionController().listen((LatLng position) {
            TelegramController().sendRequest({
                '@type': 'geochats.getLocated',
                'geo_point': <String, double>{
                    'lat': position.latitude,
                    'long': position.longitude
                },
                'radius': searchRadius,
                'limit': searchLimit
            }, (Map<String, dynamic> received) {
                print(received);
            });
        });
    }

    Future<List<dynamic>> getCurrentList() {
        return _geochatListStreamController.stream.last;
    }

    StreamSubscription<List<dynamic>> listen(void onData(List<dynamic> event),
        { Function onError, void onDone(), bool cancelOnError }) {
        return _geochatListStreamController.stream.listen(onData);
    }

    void dispose() {
        _positionStreamSubscription.cancel();
        _geochatListStreamController.close();
    }

}
