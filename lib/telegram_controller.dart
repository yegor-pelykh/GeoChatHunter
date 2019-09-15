import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geochat_hunter/package_info_controller.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geochat_hunter/restricted_access_data.dart' as RestrictedAccessData;

final String messageClientStarted = 'ClientStarted';
final double updateWaitTimeout = 0.0;

class _RequestInfo {
    final String key;
    final Function(Map<String, dynamic>) callback;

    const _RequestInfo(this.key, this.callback);
}

enum AuthorizationState {
    processing,
    waitPhoneNumber,
    waitCode,
    ready
}

class TelegramController {
    // Singleton implementation
    static final TelegramController _instance = TelegramController._internal();
    factory TelegramController() => _instance;

    // Internal fields (final)
    final _platform = MethodChannel(RestrictedAccessData.tdChannelName);
    // Internal fields
    bool _receivingUpdates;
    StreamController<Map<String, dynamic>> _updateStreamController;
    StreamController<AuthorizationState> _authorizationStateStreamController;
    List<_RequestInfo> _requestList;
    int _requestId;
    int _clientId;
    Lock _lock;
    Directory _appDocDir;
    Directory _appExtDir;

    TelegramController._internal() {
        _receivingUpdates = false;
        _updateStreamController = StreamController.broadcast();
        _authorizationStateStreamController = StreamController.broadcast();
        _requestList = List<_RequestInfo>();
        _requestId = 0;
        _lock = Lock();
        _createClient();
    }

    Future _createClient() async {
        if (_clientId != null)
            return;

        try {
            _clientId = await _platform.invokeMethod('clientCreate');
            _appDocDir = await getApplicationDocumentsDirectory();
            _appExtDir = await getExternalStorageDirectory();
            startReceiveUpdates();
            sendAuthorizationRequest({
                '@type': 'getAuthorizationState'
            });
        } on PlatformException catch (e) {
            print(e);
        }
    }

    StreamSubscription<Map<String, dynamic>> listenUpdates(void onData(Map<String, dynamic> event),
        { Function onError, void onDone(), bool cancelOnError }) {
        return _updateStreamController.stream.listen(onData);
    }

    StreamSubscription<AuthorizationState> listenAuthorizationState(void onData(AuthorizationState event),
        { Function onError, void onDone(), bool cancelOnError }) {
        return _authorizationStateStreamController.stream.listen(onData);
    }

    Future startReceiveUpdates() async {
        if (_receivingUpdates == true)
            return;

        _receivingUpdates = true;
        Future.doWhile(() async {
            try {
                String result = await _platform.invokeMethod('clientReceive', <String, Object>{
                    'client': _clientId,
                    'timeout': updateWaitTimeout
                });
                if (result != null) {
                    Map<String, dynamic> jsonData = json.decode(result);
                    await _lock.synchronized(() async {
                        for (int i = 0; i < _requestList.length; i++) {
                            if (_requestList[i].key == jsonData['@extra']) {
                                var func = _requestList[i].callback;
                                if (func != null)
                                    func(jsonData);
                                _requestList.removeAt(i);
                                break;
                            }
                        }
                    });
                    _updateStreamController.add(jsonData);
                }
            } on PlatformException catch (e) {
                print(e);
            }
            return _receivingUpdates;
        });
    }

    void stopReceiveUpdates() {
        _receivingUpdates = false;
    }

    Future sendRequest(Map<String, dynamic> request, Function(Map<String, dynamic>) callback) async {
        if (callback != null) {
            await _lock.synchronized(() async {
                _requestId++;
                String key = _requestId.toString();
                request['@extra'] = key;
                _requestList.add(_RequestInfo(key, callback));
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

    Future sendAuthorizationRequest(Map<String, dynamic> request) async {
        return sendRequest(request, _checkAuthorization);
    }

    Future _checkAuthorization(Map<String, dynamic> receivedData) async {
        final type = receivedData['@type'];
        switch (type) {
            case 'authorizationStateWaitTdlibParameters':
                final packageInfo = await PackageInfoController().getPackageInfo();
                sendAuthorizationRequest({
                    '@type': 'setTdlibParameters',
                    'parameters': {
                        'use_test_dc': false,
                        'api_id': RestrictedAccessData.tdAppId,
                        'api_hash': RestrictedAccessData.tdAppHash,
                        'device_model': 'Device',
                        'system_version': 'SysVersion',
                        'application_version': packageInfo.version,
                        'system_language_code': 'en',
                        'database_directory': _appDocDir.path,
                        'files_directory': _appExtDir.path + '/gch',
                        'use_file_database': true,
                        'use_chat_info_database': true,
                        'use_message_database': true,
                        'ignore_file_names': true,
                        'enable_storage_optimizer': true
                    }
                });
                break;
            case 'authorizationStateWaitEncryptionKey':
                sendAuthorizationRequest({
                    '@type': 'checkDatabaseEncryptionKey',
                    'encryption_key': RestrictedAccessData.tdEncryptionKey
                });
                break;
            case 'authorizationStateReady':
                _authorizationStateStreamController.add(AuthorizationState.ready);
                stopReceiveUpdates();
                break;
            case 'authorizationStateWaitPhoneNumber':
                _authorizationStateStreamController.add(AuthorizationState.waitPhoneNumber);
                break;
            case 'authorizationStateWaitCode':
                _authorizationStateStreamController.add(AuthorizationState.waitCode);
                break;
            case 'ok':
                sendAuthorizationRequest({
                    '@type': 'getAuthorizationState'
                });
                break;
            case 'authorizationStateLoggingOut':
                break;
            case 'authorizationStateClosing':
                break;
            case 'authorizationStateClosed':
                break;
            default:
        }
    }

    void dispose() {
        stopReceiveUpdates();
        _authorizationStateStreamController.close();
    }

}
