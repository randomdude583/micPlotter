import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:mic_analyzer/barChartPainter.dart';

class PlotterWidget extends StatefulWidget {

  //Stream of microphone samples
  final Stream<List<int>> sampleStream;

  //Sample rate of the microphone stream(Hz). MUST BE ACCURATE.
  final int sampleRate;

  //Size of Y axis (amplitude). A value of 0.5 will show values from -.5 to .5
  final double yAxisMax;

  //Distance between ticks on the Y axis.
  final double yAxisResolution;

  //Size of X axis (time). How many seconds of data should be saved.
  final double xAxisMemorySize;

  //How many seconds should be displayed
  final double xAxisVisibleSize;

  //Number of data points to be displayed on screen at once.
  final int resolution;



  //Constructor
  PlotterWidget({
    @required this.sampleStream,
    @required this.sampleRate,
    this.yAxisMax: .5,          //not yet implemented  TODO
    this.yAxisResolution: .25,  //not yet implemented  TODO
    this.xAxisMemorySize: 5,
    this.xAxisVisibleSize: 1,
    this.resolution: 50,
  });


  @override
  State<StatefulWidget> createState() {
    return _PlotterWidgetState(sampleStream, sampleRate, yAxisMax, yAxisResolution, xAxisMemorySize, xAxisVisibleSize, resolution);
  }

}




class _PlotterWidgetState extends State {

  //Parameters
  final Stream<List<int>> sampleStream;
  final int sampleRate;
  final double yAxisMax;
  final double yAxisResolution;
  final double xAxisMemorySize;
  final double xAxisVisibleSize;
  final int resolution;

  //Constructor
  _PlotterWidgetState(
    this.sampleStream,
    this.sampleRate,
    this.yAxisMax,
    this.yAxisResolution,
    this.xAxisMemorySize,
    this.xAxisVisibleSize,
    this.resolution,
  );


  //Variables
  StreamSubscription<List<int>> listener;
  double oldxAxisVisibleSize;
  int memoryQueueSize;
  Queue<int> memoryQueue = new Queue();
  Queue<double> graphPointsQueue = new Queue();
  int dataPointsPerBar;
  int dataPointsSinceLastUpdate;





  @override
  void initState() {
    testArgs();
    oldxAxisVisibleSize = xAxisVisibleSize;
    memoryQueueSize = (sampleRate * xAxisMemorySize).toInt();
    memoryQueueSize -= memoryQueueSize % resolution;

    dataPointsPerBar = ((sampleRate * xAxisVisibleSize) / resolution).floor();
    dataPointsSinceLastUpdate = 0;


   //initialize graph points
    if(graphPointsQueue.length == 0){
      for(int i=0; i < resolution; i++){
        graphPointsQueue.add(0);
      }
    }







    // Start listening to the stream
    listener = sampleStream.asBroadcastStream().listen((samples) {
      setState(() {

        //Update queue
        //Iterate through samples and add to queue.
        for(int i=0; i<samples.length; i++){
          memoryQueue.add(samples[i]);

          if(memoryQueue.length > memoryQueueSize){
            //remove first from queue to keep at defined size
            memoryQueue.removeFirst();
          }
          dataPointsSinceLastUpdate += 1;

          if(dataPointsSinceLastUpdate >= dataPointsPerBar){
            dataPointsSinceLastUpdate = 0;

            //add new bar to graphPointsQueue
            int offset = memoryQueue.length-dataPointsPerBar;

            double curMax = 0;
            int counter = 0;
            for(i=offset; i<memoryQueue.length; i++){
              counter ++;
              double value = (memoryQueue.elementAt(i)/255) - .5 ;
              if(value > curMax){
                curMax = value;
              }
            }

            graphPointsQueue.add(curMax);
            if(graphPointsQueue.length > resolution){
              graphPointsQueue.removeFirst();
            }
          }
        }
      });
    });

    super.initState();
  }





  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      child: Container(
        height: 300.0,
      ),
      painter: BarChartPainter(
        graphPoints: graphPointsQueue.toList(),
        gapPercentage: 5/10,
        color: Colors.orange,
      ),
    );
  }















  void testArgs(){
    if(xAxisVisibleSize > xAxisMemorySize){
      throw Exception("xAxisVisibleSize must be smaller than xAxisMemorySize");
    }
    if(xAxisMemorySize < 0){
      throw Exception("xAxisMemorySize must be greater than 0");
    }
    if(xAxisVisibleSize < 0){
      throw Exception("xAxisVisibleSize must be greater than 0");
    }
    if(resolution < 0){
      throw Exception("resolution must be greater than 0");
    }

  }
}