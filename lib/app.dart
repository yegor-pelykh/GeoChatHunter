import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geochat_hunter/definitions.dart' as Definitions;
import 'package:geochat_hunter/telegram_controller.dart';
import 'package:geochat_hunter/position_controller.dart';
import 'package:geochat_hunter/geochat_provider.dart';
import 'package:geochat_hunter/login_page.dart';
import 'package:geochat_hunter/main_page.dart';
import 'package:geochat_hunter/processing_page.dart';

void main() => runApp(GeochatHunterApp());

class GeochatHunterApp extends StatefulWidget {
    const GeochatHunterApp({Key key}) : super(key: key);

    @override
    _GeochatHunterAppState createState() => _GeochatHunterAppState();
}

class _GeochatHunterAppState extends State<GeochatHunterApp> with TickerProviderStateMixin {
    AuthorizationState _authorizationState;
    StreamSubscription<AuthorizationState> _authStateStreamSubscription;

    _GeochatHunterAppState() {
        GeochatProvider();
        _subscribeToAuthorizationState();
    }

    void _subscribeToAuthorizationState() {
        if (_authStateStreamSubscription != null)
            return;

        _authStateStreamSubscription = TelegramController().listenAuthorizationState((AuthorizationState state) {
            setState(() {
                _authorizationState = state;
            });
        });
    }

    @override
    void initState() {
        super.initState();
    }

    Widget getHomePage() {
        switch (_authorizationState) {
            case AuthorizationState.waitPhoneNumber:
                return LoginPage(
                    mode: LoginPageMode.phone
                );
            case AuthorizationState.waitCode:
                return LoginPage(
                    mode: LoginPageMode.code
                );
            case AuthorizationState.ready:
                return MainPage();
            case AuthorizationState.processing:
            default:
                return ProcessingPage();
        }
    }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: Definitions.appTitle,
            home: getHomePage()
        );
    }

    @override
    void dispose() {
        _authStateStreamSubscription.cancel();
        GeochatProvider().dispose();
        TelegramController().dispose();
        PositionController().dispose();
        super.dispose();
    }

}
