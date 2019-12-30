import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

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
  StreamSubscription<List<int>> listener;
  List<Series<SamplePoint, double>> dataSets;
  int xAxisSize = 40000;//points
  Queue<SamplePoint> dataQueue = new Queue();
  int dataPointSinceLastUpdate = 0;   //How many data points have been loaded since last refresh.
  int dataPointsBeforeRefresh = 1000; //How many data points should be loaded before refreshing the map.
  bool isPaused = false;
  AnimationController _pauseBtnController;

  @override
  void initState() {

    _pauseBtnController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));


    dataQueue.add(SamplePoint(0, 0)); //Initial Point
    dataSets = [
      new Series<SamplePoint, double>(
        id: 'terrain',
        colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
        domainFn: (SamplePoint point, _) => point.distance,
        measureFn: (SamplePoint point, _) => point.amplitude,
        data: dataQueue.toList(),
      )
    ];

    _startListener();

    super.initState();
  }

  void _startListener(){
    // Init a new Stream
    Stream<List<int>> stream = microphone(sampleRate: 44100);

    // Start listening to the stream
    listener = stream.listen((samples) {
      //Update graph
      setState(() {
        //Iterate through samples and add to queue.
        for(int i=0; i<samples.length; i++){
          double amplitude = samples[i].toDouble();
          amplitude = (amplitude/255) - .5;
          double distance = dataQueue.elementAt(dataQueue.length-1).distance+1;
          dataQueue.add(new SamplePoint(distance, amplitude));
          if(dataQueue.length > xAxisSize){
            //remove first from queue to keep at defined size
            dataQueue.removeFirst();
          }
          //keep track of how long since the last graph update
          dataPointSinceLastUpdate+=1;
        }


        //if it has been long enough since last graph update, update the graph
        if(dataPointSinceLastUpdate >= dataPointsBeforeRefresh){
          dataPointSinceLastUpdate = 0;
          dataSets = [
            Series<SamplePoint, double>(
              id: 'waveform',
              colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
              domainFn: (SamplePoint point, _) => point.distance,
              measureFn: (SamplePoint point, _) => point.amplitude,
              data: dataQueue.toList(),
            ),
          ];
        }
      });
    });
  }

  void _stopListener(){
    //Pause the subscription
    listener.cancel();
  }







  @override
  void dispose() {
    // Cancel the subscription
    listener.cancel();
    _pauseBtnController.dispose();

    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 200,
              child: LineChart(
                dataSets,
                animate: false,
                primaryMeasureAxis: new NumericAxisSpec(
                  tickProviderSpec: new StaticNumericTickProviderSpec(
                      <TickSpec<num>>[
                        TickSpec(-.4),
                        TickSpec(-.2),
                        TickSpec(0),
                        TickSpec(.2),
                        TickSpec(.4),
                      ]
                  ),
                  showAxisLine: true,

                ),
                domainAxis: new NumericAxisSpec(
                  renderSpec: NoneRenderSpec(),
                  tickProviderSpec: new NumericEndPointsTickProviderSpec(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          isPaused = !isPaused;
          if(isPaused){
            _pauseBtnController.forward();
            _stopListener();
          } else {
            _pauseBtnController.reverse();
            _startListener();
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


class SamplePoint {
  final double distance;
  final double amplitude;

  SamplePoint(this.distance, this.amplitude);


  @override
  String toString() {
    // TODO: implement toString
    return "(" + distance.toString() + ", " + amplitude.toString() +  ")";
  }
}