class TimePlannerDateTime {
  DateTime dateTime;

  /// Day index from 0, this index dependence on your time planner header
  int day;

  /// Task will be begin at this hour
  int hour;

  /// Task will be begin at this minutes
  int minutes;

  bool isAllDayEvent;

  TimePlannerDateTime(
      {required this.day,
      required this.hour,
      required this.minutes,
      required this.dateTime,
      this.isAllDayEvent = false});
}
