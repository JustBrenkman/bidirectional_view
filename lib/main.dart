import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';

import 'package:bidirectional_view/bidirectional_view.dart';

void main() {
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bi-directional View',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Bi-directional View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: 100,
      height: 100,
      color: Colors.red,
    );

    BiDirectionalLayout layout = BiDirectionalLayout(children: <BiWrapper>[
      BiWrapper(child: child, worldPos: Offset(0, 0)),
      BiWrapper(child: child, worldPos: Offset(600, -300),),
      BiWrapper(child: Container(width: 100, height: 300, child: RaisedButton(onPressed: () => print('hello'),),), worldPos: Offset(600, 300),)
    ]);

    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => layout,
        child: Consumer(
          builder: (BuildContext context, BiDirectionalLayout _layout, Widget child) {
            return BiDirectionalView(layout: _layout);
          }
        ),
      ),
    );
  }
}
