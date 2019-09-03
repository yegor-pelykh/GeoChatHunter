import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoChat Hunter',
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('GeoChat Hunter'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Map', icon: Icon(Icons.map)),
                Tab(text: 'GeoChats', icon: Icon(Icons.view_list))
              ],
            )
          ),
          body: TabBarView(
            children: [
              Icon(Icons.map),
              Icon(Icons.view_list)
            ],
          ),
        ),
      ),
    );
  }
}

void main() => runApp(MyApp());