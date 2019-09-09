import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';
import 'restricted_data.dart' as RestrictedData;

final String msgClientStarted = 'ClientStarted';
final double updateWaitTimeout = 10.0;

final _platform = new MethodChannel(RestrictedData.tdChannelName);

enum AuthorizationState {
    processing,
    infoNeeded,
    ready
}

class TelegramController {
    String _appVersion;
    Function(AuthorizationState) _authorizationStateChanged;
    bool _receivingUpdates;
    StreamController<String> _updateStreamController;
    StreamSubscription<String> _updateStreamSubscription;
    List _requestList;
    int _requestId;
    int _clientId;
    Lock _lock;
    Directory _appDocDir;
    Directory _appExtDir;

    TelegramController({
        @required String appVersion,
        Function(AuthorizationState) authorizationStateChanged
    }) {
        _appVersion = appVersion;
        _authorizationStateChanged = authorizationStateChanged;
        _receivingUpdates = false;
        _updateStreamController = new StreamController.broadcast();
        _requestList = new List();
        _requestId = 0;
        _lock = new Lock();
        _setAuthorizationState(AuthorizationState.processing);
        _subscribeToUpdates();
        _createClient();
    }

    void _setAuthorizationState(AuthorizationState state) {
        if (_authorizationStateChanged != null)
            _authorizationStateChanged(state);
    }

    void _subscribeToUpdates() {
        if (_updateStreamController == null)
            return;

        _updateStreamSubscription = _updateStreamController.stream.listen((String data) {
            if (data == msgClientStarted) {
                sendRequest({
                    '@type': 'getAuthorizationState'
                }, _checkAuthorization);
            }
            dynamic jsonData = json.decode(data);
            switch (jsonData['@type']) {
                // TODO
            }
        });
    }

    Future<void> _createClient() async {
        if (_clientId != null)
            return;

        try {
            _clientId = await _platform.invokeMethod('clientCreate');
            _appDocDir = await getApplicationDocumentsDirectory();
            _appExtDir = await getExternalStorageDirectory();
            _updateStreamController.add(msgClientStarted);
            _startReceive();
        } on PlatformException catch (e) {
            print(e);
        }
    }

    Future<void> _startReceive() async {
        if (_receivingUpdates || _updateStreamController == null)
            return;

        _receivingUpdates = true;
        while (_receivingUpdates) {
            try {
                String result = await _platform.invokeMethod('clientReceive', <String, Object>{
                    'client': _clientId,
                    'timeout': updateWaitTimeout
                });
                if (result != null) {
                    Map<String, dynamic> jsonData = json.decode(result);
                    await _lock.synchronized(() {
                        for (int i = 0; i < _requestList.length; i++) {
                            if (_requestList[i][0] == jsonData['@extra']) {
                                var func = _requestList[i][1];
                                if (func != null)
                                    func(jsonData);
                                _requestList.removeAt(i);
                                break;
                            }
                        }
                    });
                    _updateStreamController.add(result);
                }
            } on PlatformException catch (e) {
                print(e);
            }
        }
    }

    void _stopReceive() {
        _receivingUpdates = false;
    }

    void _checkAuthorization(Map<String, dynamic> receivedData) {
        switch (receivedData['@type']) {
            case 'authorizationStateWaitTdlibParameters':
                sendRequest({
                    '@type': 'setTdlibParameters',
                    'parameters': {
                        'use_test_dc': false,
                        'api_id': RestrictedData.tdAppId,
                        'api_hash': RestrictedData.tdAppHash,
                        'device_model': 'Device',
                        'system_version': 'SysVersion',
                        'application_version': _appVersion,
                        'system_language_code': 'en',
                        'database_directory': _appDocDir.path,
                        'files_directory': _appExtDir.path + '/tg',
                        'use_file_database': true,
                        'use_chat_info_database': true,
                        'use_message_database': true,
                        'ignore_file_names': true,
                        'enable_storage_optimizer': true
                    }
                }, _checkAuthorization);
                break;
            case 'authorizationStateWaitEncryptionKey':
                sendRequest({
                    '@type': 'checkDatabaseEncryptionKey',
                    'encryption_key': RestrictedData.tdEncryptionKey
                }, _checkAuthorization);
                break;
            case 'authorizationStateReady':
                _setAuthorizationState(AuthorizationState.ready);
                break;
            case 'authorizationStateWaitPhoneNumber':
            case 'authorizationStateWaitCode':
            case 'authorizationStateWaitPassword':
                _setAuthorizationState(AuthorizationState.infoNeeded);
                break;
            case 'ok':
                sendRequest({
                    '@type': 'getAuthorizationState'
                }, _checkAuthorization);
                break;
            default:
        }
        print(receivedData);
    }

    Future<void> sendRequest(Map<String, dynamic> request, Function(Map<String, dynamic>) callback) async {
        if (callback != null) {
            await _lock.synchronized(() {
                _requestId++;
                request['@extra'] = _requestId.toString();
                _requestList.add([
                    _requestId.toString(),
                    callback
                ]);
            });
        }
        try {
            await _platform.invokeMethod('clientSend', {
                'client': _clientId,
                'query': json.encode(request)
            });
        } on PlatformException catch (e) {
            print(e);
        }
    }

    void dispose() {
        _stopReceive();
        _updateStreamSubscription.cancel();
    }

}
