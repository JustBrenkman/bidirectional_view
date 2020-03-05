import 'dart:io';

import 'package:bidirectional_view/bidirectional_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
    return Scaffold(
      body: Container(
        child: BiDirectionalView(
          children: <BiWrapper>[
            BiWrapper(size: Size(10, 10),),
            BiWrapper(offset: Offset(100, 100),)
          ]
        ),
      )
    );
  }
}
