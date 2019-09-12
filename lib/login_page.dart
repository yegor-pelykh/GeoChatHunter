import 'package:flutter/material.dart';
import 'package:geochat_hunter/telegram_controller.dart';
import 'definitions.dart' as Definitions;

enum LoginPageMode {
    phone,
    code
}

class LoginPage extends StatefulWidget {
    final TelegramController _telegramController;
    final LoginPageMode _mode;

    const LoginPage({
        Key key,
        @required TelegramController telegramController,
        @required LoginPageMode mode
    }) :
            _telegramController = telegramController,
            _mode = mode,
            super(key: key);

    @override
    _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    TextEditingController _loginPhoneController;
    TextEditingController _loginCodeController;

    _LoginPageState() {
        _loginPhoneController = TextEditingController();
        _loginCodeController = TextEditingController();
    }

    @override
    void initState() {
        super.initState();
    }

    List<Widget> getPhoneContent() {
        return [
            TextFormField(
                controller: _loginPhoneController,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: UnderlineInputBorder(
                        borderSide: new BorderSide(color: Colors.white),
                        borderRadius: new BorderRadius.circular(8),
                    ),
                    hintText: 'Phone',
                    contentPadding: EdgeInsets.all(8.0)
                ),
            ),
            SizedBox(height: 8.0),
            RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                ),
                onPressed: () {
                    final controller = widget._telegramController;
                    if (controller == null)
                        return;
                    controller.sendAuthorizationRequest({
                        '@type': 'setAuthenticationPhoneNumber',
                        'phone_number': _loginPhoneController.text
                    });
                },
                padding: EdgeInsets.all(8),
                color: Colors.lightBlueAccent,
                child: Text('Get code', style: TextStyle(color: Colors.white)),
            )
        ];
    }

    List<Widget> getCodeContent() {
        return [
            TextFormField(
                controller: _loginCodeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: UnderlineInputBorder(
                        borderSide: new BorderSide(color: Colors.white),
                        borderRadius: new BorderRadius.circular(8),
                    ),
                    hintText: 'Code',
                    contentPadding: EdgeInsets.all(8.0)
                ),
            ),
            SizedBox(height: 8.0),
            RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                ),
                onPressed: () {
                    final controller = widget._telegramController;
                    if (controller == null)
                        return;
                    controller.sendAuthorizationRequest({
                        '@type': 'checkAuthenticationCode',
                        'code': _loginCodeController.text
                    });
                },
                padding: EdgeInsets.all(8),
                color: Colors.lightBlueAccent,
                child: Text('Authorize', style: TextStyle(color: Colors.white)),
            )
        ];
    }

    List<Widget> getEmptyContent() {
        return null;
    }

    List<Widget> getContent() {
        switch (widget._mode) {
            case LoginPageMode.phone:
                return getPhoneContent();
            case LoginPageMode.code:
                return getCodeContent();
            default:
                return getEmptyContent();
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(Definitions.appTitle)
            ),
            backgroundColor: Colors.blue,
            body: Center(
                child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
                    children: getContent()
                )
            )
        );
    }

    @override
    void dispose() {
        super.dispose();
    }

}
