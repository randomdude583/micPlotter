import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart';

class PlotterWidget extends StatefulWidget {

  //Stream of microphone samples
  final Stream<List<int>> sampleStream;

  //Sample rate of the microphone stream(Hz). MUST BE ACCURATE.
  final int sampleRate;

  //Size of Y axis (amplitude). A value of 0.5 will show values from -.5 to .5
  final double yAxisMax;

  //Distance between ticks on the Y axis.
  final double yAxisResolution;

  //Size of X axis (time). How many seconds of data should be displayed.
  final double xAxisSize;

  //Number of data points to be displayed on screen at once.
  final int resolution;

  //Graph refresh rate (Hz)
  final int refreshRate;


  //Constructor
  PlotterWidget({
    @required this.sampleStream,
    @required this.sampleRate,
    this.yAxisMax: .5,
    this.yAxisResolution: .25,
    this.xAxisSize: 1,
    this.resolution: 500,
    this.refreshRate: 30,
  });


  @override
  State<StatefulWidget> createState() {
    return _PlotterWidgetState(sampleStream, sampleRate, yAxisMax, yAxisResolution, xAxisSize, resolution, refreshRate);
  }

}




class _PlotterWidgetState extends State {

  //Parameters
  final Stream<List<int>> sampleStream;
  final int sampleRate;
  final double yAxisMax;
  final double yAxisResolution;
  final double xAxisSize;
  final int resolution;
  final int refreshRate;

  //Constructor
  _PlotterWidgetState(
    this.sampleStream,
    this.sampleRate,
    this.yAxisMax,
    this.yAxisResolution,
    this.xAxisSize,
    this.resolution,
    this.refreshRate,
  );


  //Variables
  StreamSubscription<List<int>> listener;
  int queueSize;
  Queue<int> dataQueue = new Queue();
  List<Series<SamplePoint, double>> dataSets;
  List<TickSpec<num>> yAxisTicks = new List<TickSpec<num>>();





  @override
  void initState() {
    queueSize = (sampleRate * xAxisSize).toInt();
    yAxisTicks.add(TickSpec(0));
    for(double i=0+yAxisResolution; i<=yAxisMax; i = num.parse((i+yAxisResolution).toStringAsFixed(5))){
      yAxisTicks.add(TickSpec(i));
      yAxisTicks.add(TickSpec(0-i));
    }



    int dataPointsBeforeRefresh = (sampleRate / refreshRate).toInt();
    int dataPointSinceLastUpdate = 0;


    dataQueue.add(0); //Initial Point
    List<SamplePoint> displayPoints = new List<SamplePoint>();
    displayPoints.add(SamplePoint(0, 0));


    dataSets = [
      new Series<SamplePoint, double>(
        id: 'terrain',
        colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
        domainFn: (SamplePoint point, _) => point.distance,
        measureFn: (SamplePoint point, _) => point.amplitude,
        data: displayPoints,
      )
    ];



    // Start listening to the stream
    listener = sampleStream.asBroadcastStream().listen((samples) {
      setState(() {


        //Update queue
        //Iterate through samples and add to queue.
        for(int i=0; i<samples.length; i++){
          dataQueue.add(samples[i]);
          if(dataQueue.length > queueSize){
            //remove first from queue to keep at defined size
            dataQueue.removeFirst();
          }
          //keep track of how long since the last graph update
          dataPointSinceLastUpdate+=1;
        }







        //if it has been long enough since last graph update, update the graph
        if(dataPointSinceLastUpdate >= dataPointsBeforeRefresh){
          dataPointSinceLastUpdate = 0;

          List<SamplePoint> displayPoints = new List<SamplePoint>();
          for(int i=0; i<=dataQueue.length-1; i+=10){
            displayPoints.add(
                SamplePoint(i.toDouble(), (dataQueue.elementAt(i)/255) - .5)
            );
          }


          dataSets = [
            Series<SamplePoint, double>(
              id: 'waveform',
              colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
              domainFn: (SamplePoint point, _) => point.distance,
              measureFn: (SamplePoint point, _) => point.amplitude,
              data: displayPoints,
            ),
          ];
        }
      });
    });

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return LineChart(
      dataSets,
      animate: false,
      primaryMeasureAxis: new NumericAxisSpec(
        tickProviderSpec: new StaticNumericTickProviderSpec(yAxisTicks),
        showAxisLine: true,
      ),
      domainAxis: new NumericAxisSpec(
        renderSpec: NoneRenderSpec(),
        tickProviderSpec: new NumericEndPointsTickProviderSpec(),
      ),
    );





  }
}








class SamplePoint {
  final double distance;
  final double amplitude;

  SamplePoint(this.distance, this.amplitude);
}