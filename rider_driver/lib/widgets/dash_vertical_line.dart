import 'package:flutter/material.dart';

/// A reusable dashed vertical line widget
class DashVerticalLine extends StatelessWidget {
  final double dashHeight;
  final double dashWidth;
  final double dashGap;
  final Color color;

  const DashVerticalLine({
    super.key,
    this.dashHeight = 4,
    this.dashWidth = 1,
    this.dashGap = 4,
    this.color = Colors.black26,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxHeight / (dashHeight + dashGap))
            .floor();

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(dashCount, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: dashGap),
              child: SizedBox(
                height: dashHeight,
                width: dashWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/*
USAGE EXAMPLE:

SizedBox(
  height: 80,
  child: DashVerticalLine(
    dashHeight: 6,
    dashWidth: 2,
    dashGap: 4,
    color: Colors.grey,
  ),
)
*/
