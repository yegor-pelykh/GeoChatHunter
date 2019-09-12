import 'package:flutter/material.dart';
import 'package:geochat_hunter/map_tab.dart';
import 'package:geochat_hunter/geochats_tab.dart';
import 'definitions.dart' as Definitions;

final List<Tab> tabs = [
    Tab(text: 'Map', icon: Icon(Icons.map)),
    Tab(text: 'GeoChats', icon: Icon(Icons.view_list))
];

class MainPage extends StatefulWidget {
    const MainPage({Key key}) : super(key: key);

    @override
    _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
    TabController _tabController;

    _MainPageState() {
        _tabController = TabController(vsync: this, length: tabs.length);
    }

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Text(Definitions.appTitle),
                bottom: TabBar(controller: _tabController, tabs: tabs)),
            body: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                    MapTab(),
                    GeoChatsTab()
                ],
            ),
        );
    }

    @override
    void dispose() {
        _tabController.dispose();
        super.dispose();
    }

}
