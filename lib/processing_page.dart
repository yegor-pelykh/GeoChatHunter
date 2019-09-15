import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geochat_hunter/definitions.dart' as Definitions;

class ProcessingPage extends StatefulWidget {
    const ProcessingPage({Key key}) : super(key: key);

    @override
    _ProcessingPageState createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(Definitions.appTitle)
            ),
            backgroundColor: Colors.blue,
            body: SpinKitRipple(
                color: Colors.white,
                size: 100.0)
        );
    }

    @override
    void dispose() {
        super.dispose();
    }

}
