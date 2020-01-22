import 'package:flutter/material.dart';

class BarChartPainter extends CustomPainter{

  final List<double> graphPoints;
  final double gapPercentage;
  final double topSpacing;
  final double bottomSpacing;
  final Color color;
  final Color backgroundColor;
  BarChartPainter({
    @required this.graphPoints,
    this.gapPercentage: 1/10,
    this.topSpacing: .1,
    this.bottomSpacing: .05,
    this.color: Colors.red,
    this.backgroundColor: Colors.black
  });



  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = backgroundColor;
    canvas.drawRect(new Rect.fromPoints(Offset(0,0), Offset(size.width, size.height)), paint);


    paint.color = color;
    if(graphPoints != null){
      double multiplier = size.width/(graphPoints.length*(1-gapPercentage) + (graphPoints.length-1)*gapPercentage);
      double barWidth = multiplier*(1-gapPercentage);
      double gapWidth = multiplier*gapPercentage;
      double topGap = size.height * topSpacing;
      double bottomPad = size.height*bottomSpacing;


      double curX = 0;
      //Create all except last bar
      for(int i=0; i<graphPoints.length-1; i++){

        double usableSize = size.height - (bottomPad + topGap);
        double barPercentage = graphPoints.elementAt(i)*2;

        Offset bottomLeft = new Offset(curX, size.height);
        Offset topRight = new Offset(
            curX + barWidth,
            size.height - (bottomPad + (usableSize * barPercentage))
        );
        curX = curX + barWidth + gapWidth;
        canvas.drawRect(Rect.fromPoints(bottomLeft, topRight), paint);

      }

      //Create last bar, and stretch to fill to end of screen
      if(graphPoints.length >= 1){

        double usableSize = size.height - (bottomPad + topGap);
        double barPercentage = graphPoints.elementAt(graphPoints.length-1)*2;

        Offset bottomLeft = new Offset(curX, size.height);
        Offset topRight = new Offset(
            size.width,
            size.height - (bottomPad + (usableSize * barPercentage))
        );
        canvas.drawRect(Rect.fromPoints(bottomLeft, topRight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

}



