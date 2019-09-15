import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geochat_hunter/geochat_provider.dart';

class GeochatsTab extends StatefulWidget {
    const GeochatsTab({Key key}) : super(key: key);

    @override
    _GeochatsTabState createState() => _GeochatsTabState();
}

class _GeochatsTabState extends State<GeochatsTab> {
    StreamSubscription<List<dynamic>> _geochatListStreamSubscription;
    List<dynamic> _list;

    _GeochatsTabState() {
        _subscribeToGeochatListChanging();
    }

    _setList(List<dynamic> list) {
        setState(() {
            _list = list;
        });
    }

    _subscribeToGeochatListChanging() async {
        if (_geochatListStreamSubscription != null)
            return;

        _setList(await GeochatProvider().getCurrentList());
        _geochatListStreamSubscription = GeochatProvider().listen(_setList);
    }

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Icon(Icons.view_list);
    }

    @override
    void dispose() {
        _geochatListStreamSubscription.cancel();
        super.dispose();
    }

}
