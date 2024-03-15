import 'package:flutter/material.dart';
import 'package:time_planner/src/config/global_config.dart' as config;

/// Title widget for time planner
class TimePlannerTitle extends StatelessWidget {
  /// Text style for title
  final TextStyle? titleStyle;

  /// Date of each day like 03/21/2021 but you can leave it empty or write other things
  final String? date;

  /// Text style for date text
  final TextStyle? dateStyle;

  /// Title widget for time planner
  const TimePlannerTitle({
    Key? key,
    this.date,
    this.titleStyle,
    this.dateStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border:
              Border(right: BorderSide(color: Color(0xFFE9E9E9), width: 1))),
      height: 30,
      width: config.cellWidth!.toDouble(),
      child: Center(
        child: Text(
          date ?? '',
          style: dateStyle ??
              const TextStyle(color: Color(0xFF5E5E5E), fontSize: 12),
        ),
      ),
    );
  }
}
