import 'dart:async';
import 'package:latlong/latlong.dart';

class PositionController {
    // Singleton implementation
    static final PositionController _instance = PositionController._internal();
    factory PositionController() => _instance;

    // Internal fields
    StreamController<LatLng> _positionStreamController;

    PositionController._internal() {
        _positionStreamController = StreamController.broadcast();
    }

    void setNewPosition(LatLng position) {
        return _positionStreamController.add(position);
    }

    StreamSubscription<LatLng> listen(void onData(LatLng event),
        { Function onError, void onDone(), bool cancelOnError }) {
        return _positionStreamController.stream.listen(onData);
    }

    void dispose() {
        _positionStreamController.close();
    }

}
