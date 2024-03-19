import 'package:flutter/widgets.dart';

class TimePlannerbloc {
  late DateTime currentDate;

  DateTime startOfDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }
}
