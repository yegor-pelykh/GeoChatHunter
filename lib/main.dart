import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:geochat_hunter/login_page.dart';
import 'package:geochat_hunter/main_page.dart';
import 'package:geochat_hunter/processing_page.dart';
import 'definitions.dart' as Definitions;
import 'telegram_controller.dart';

void main() => runApp(GeoChatHunterApp());

class GeoChatHunterApp extends StatefulWidget {
    const GeoChatHunterApp({Key key}) : super(key: key);

    @override
    _GeoChatHunterAppState createState() => _GeoChatHunterAppState();
}

class _GeoChatHunterAppState extends State<GeoChatHunterApp> with TickerProviderStateMixin {
    PackageInfo _packageInfo;
    TelegramController _telegramController;
    AuthorizationState _authorizationState;

    @override
    void initState() {
        super.initState();
        _initPackageInfoModule().then((void _) {
            _initTelegramController();
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

    void _onTelegramAuthorizationStateChanged(AuthorizationState state) {
        setState(() {
            _authorizationState = state;
        });
    }

    Widget getHomePage() {
        switch (_authorizationState) {
            case AuthorizationState.waitPhoneNumber:
                return LoginPage(
                    telegramController: _telegramController,
                    mode: LoginPageMode.phone
                );
            case AuthorizationState.waitCode:
                return LoginPage(
                    telegramController: _telegramController,
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
        _telegramController.dispose();
        super.dispose();
    }

}
