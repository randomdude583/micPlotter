import 'dart:async';
import 'dart:collection';

import 'package:mic_analyzer/plotterWidget.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:charts_flutter/flutter.dart';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Plotter',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Mic Plotter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{
  Stream<List<int>> micStream;
  StreamController<List<int>> broadcastStreamController;
  StreamSubscription<List<int>> micStreamListener;
  bool isPaused = false;
  AnimationController _pauseBtnController;

  @override
  void initState() {
    // Init a new Stream
    micStream = microphone(sampleRate: 44100);
    broadcastStreamController = StreamController<List<int>>.broadcast();

    micStreamListener = micStream.listen((samples) {
      if(!isPaused) {
        broadcastStreamController.add(samples);
      }
    });
    _pauseBtnController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));


    super.initState();
  }









  @override
  void dispose() {
    _pauseBtnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                Container(
                  height: 200,
                  child: PlotterWidget(
                    sampleStream: broadcastStreamController.stream,
                    sampleRate: 44100,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          isPaused = !isPaused;
          if(isPaused){
            _pauseBtnController.forward();
          } else {
            _pauseBtnController.reverse();
          }
        },
        child: AnimatedIcon(
          icon: AnimatedIcons.pause_play,
          progress: _pauseBtnController,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}