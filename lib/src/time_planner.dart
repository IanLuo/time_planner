import 'package:flutter/material.dart';
import 'package:time_planner/src/bloc/time_planner_bloc.dart';
import 'package:time_planner/src/config/global_config.dart' as config;
import 'package:time_planner/src/time_planner_style.dart';
import 'package:time_planner/src/time_planner_task.dart';
import 'package:time_planner/src/time_planner_time.dart';
import 'package:time_planner/src/time_planner_title.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// Time planner widget
class TimePlanner extends StatefulWidget {
  /// Time start from this, it will start from 0
  final int startHour;

  /// Time end at this hour, max value is 23
  final int endHour;

  /// Create days from here, each day is a TimePlannerTitle.
  ///
  /// you should create at least one day
  final List<TimePlannerTitle> headers;
  final List<List<TimePlannerTask>> alldayEvents;

  /// List of widgets on time planner
  final List<TimePlannerTask>? tasks;

  /// Style of time planner
  final TimePlannerStyle? style;

  /// When widget loaded scroll to current time with an animation. Default is true
  final bool? currentTimeAnimation;

  /// Whether time is displayed in 24 hour format or am/pm format in the time column on the left.
  final bool use24HourFormat;

  //Whether the time is displayed on the axis of the tim or on the center of the timeblock. Default is false.
  final bool setTimeOnAxis;

  DateTime currentDate;
  final DateTime today;
  final DateTimeRange range;

  late final Map<String, List<TimePlannerTask>>? allTasksMap;
  final Function(DateTime startDate, DateTime endDate)? onReserveBoxSelected;
  final Function(DateTime currentDate)? onDateDisplay;
  final Function(DateTime currentDate)? onScrolEnd;

  /// Time planner widget
  TimePlanner(
      {Key? key,
      required this.startHour,
      required this.endHour,
      required this.headers,
      required this.alldayEvents,
      required this.currentDate,
      required this.today,
      required this.range,
      this.tasks,
      this.style,
      this.use24HourFormat = false,
      this.setTimeOnAxis = false,
      this.currentTimeAnimation,
      this.onReserveBoxSelected,
      this.onDateDisplay,
      this.onScrolEnd})
      : super(key: key);
  @override
  _TimePlannerState createState() => _TimePlannerState();
}

final minuteOfHour = 60.0;
final defaultMinuteHeight =
    (config.cellHeight?.toDouble() ?? 0.0) / minuteOfHour;
final _hourOfheight = minuteOfHour * defaultMinuteHeight;

class _TimePlannerState extends State<TimePlanner> {
  ScrollController mainHorizontalController = ScrollController();
  ScrollController mainVerticalController = ScrollController();
  ScrollController dayHorizontalController = ScrollController();
  ScrollController timeVerticalController = ScrollController();
  TimePlannerbloc bloc = TimePlannerbloc();
  TimePlannerStyle style = TimePlannerStyle();
  BehaviorSubject<List<TimePlannerTask>> tasks = BehaviorSubject.seeded([]);
  bool? isAnimated = true;
  bool _displayReserve = false;
  double _reserveOffsetY = 0;
  int offsetIndex = 0;
  DateTime? _currentOutPutDay = null;
  int currentDayDistance = 0;

  /// check input value rules
  void _checkInputValue() {
    if (widget.startHour > widget.endHour) {
      throw FlutterError("Start hour should be lower than end hour");
    } else if (widget.startHour < 0) {
      throw FlutterError("Start hour should be larger than 0");
    } else if (widget.endHour > 23) {
      throw FlutterError("Start hour should be lower than 23");
    } else if (widget.headers.isEmpty) {
      throw FlutterError("header can't be empty");
    }
  }

  /// create local style
  void _convertToLocalStyle() {
    style.backgroundColor = widget.style?.backgroundColor;
    style.cellHeight = widget.style?.cellHeight ?? 80;
    style.cellWidth = widget.style?.cellWidth ?? 90;
    style.horizontalTaskPadding = widget.style?.horizontalTaskPadding ?? 0;
    style.borderRadius = widget.style?.borderRadius ??
        const BorderRadius.all(Radius.circular(8.0));
    style.dividerColor = widget.style?.dividerColor;
    style.interstitialOddColor = widget.style?.interstitialOddColor;
    style.interstitialEvenColor = widget.style?.interstitialEvenColor;
  }

  /// store input data to static values
  void _initData() {
    _checkInputValue();
    _convertToLocalStyle();
    config.horizontalTaskPadding = style.horizontalTaskPadding;
    config.cellHeight = style.cellHeight;
    config.cellWidth = style.cellWidth;
    config.totalHours = (widget.endHour - widget.startHour).toDouble();
    config.totalDays = widget.headers.length;
    config.startHour = widget.startHour;
    config.use24HourFormat = widget.use24HourFormat;
    config.setTimeOnAxis = widget.setTimeOnAxis;
    config.borderRadius = style.borderRadius;
    isAnimated = widget.currentTimeAnimation;
    final allTasks = widget.tasks ?? [];
    widget.allTasksMap = allTasks.fold<Map<String, List<TimePlannerTask>>>(
        <String, List<TimePlannerTask>>{},
        (Map<String, List<TimePlannerTask>> map, TimePlannerTask task) {
      String key =
          "${task.dateTime.dateTime.year}${task.dateTime.dateTime.month}${task.dateTime.dateTime.day}";
      // task.dateTime.day.toString();
      if (map.containsKey(key)) {
        map[key]!.add(task);
      } else {
        map[key] = <TimePlannerTask>[task];
      }
      return map;
    });

    allTasks.forEach((task) {
      task.setAllTasks(widget.allTasksMap!);
    });
    tasks.add(allTasks);
  }

  void _addListen() {
    Future.delayed(Duration.zero).then((_) {
      int hour = DateTime.now().hour;
      if (isAnimated != null && isAnimated == true) {
        if (hour > widget.startHour) {
          double scrollOffset =
              (hour - widget.startHour) * config.cellHeight!.toDouble();
          mainVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
          timeVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
        }
      }
    });

    final currentDayOffset = offsetOfDate(this.widget.currentDate);

    mainHorizontalController.addListener(() {
      dayHorizontalController.jumpTo(mainHorizontalController.offset);

      final outPutDay = outputDayOfOffset(currentDayOffset: currentDayOffset);

      if (isSameDay(date1: _currentOutPutDay, date2: outPutDay) == true) {
        return;
      }
      _currentOutPutDay = outPutDay;
      if (this.widget.onDateDisplay != null) {
        if (_currentOutPutDay != null) {
          this.widget.onDateDisplay!(_currentOutPutDay!);
        }
      }
    });

    mainVerticalController.addListener(() {
      timeVerticalController.jumpTo(mainVerticalController.offset);
    });
  }

  void animateToDayOffset(double dayOffSet) {
    Future.delayed(Duration.zero).then((_) {
      mainHorizontalController.animateTo(dayOffSet,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCirc);
      dayHorizontalController.animateTo(dayOffSet,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCirc);
    });
  }

  @override
  void initState() {
    _addListen();
    _initData();
    super.initState();
    final currentDayOffset = offsetOfDate(this.widget.currentDate);
    animateToDayOffset(currentDayOffset);
    setState(() {
      this.currentDayDistance =
          widget.range.start.difference(this.widget.today).inDays.abs();
    });
  }

  @override
  void didUpdateWidget(TimePlanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      final allTasks = widget.tasks ?? [];
      widget.allTasksMap = allTasks.fold<Map<String, List<TimePlannerTask>>>(
          <String, List<TimePlannerTask>>{},
          (Map<String, List<TimePlannerTask>> map, TimePlannerTask task) {
        String key =
            "${task.dateTime.dateTime.year}${task.dateTime.dateTime.month}${task.dateTime.dateTime.day}";
        // task.dateTime.day.toString();
        if (map.containsKey(key)) {
          map[key]!.add(task);
        } else {
          map[key] = <TimePlannerTask>[task];
        }
        return map;
      });

      allTasks.forEach((task) {
        task.setAllTasks(widget.allTasksMap!);
      });
      tasks.add(allTasks);
    });
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axisDirection == AxisDirection.left ||
        notification.metrics.axisDirection == AxisDirection.right) {
      if (notification is ScrollEndNotification) {
        //Scroll End

        final currentDayOffset = offsetOfDate(this.widget.currentDate);
        final diff = currentDayOffset - mainHorizontalController.offset;
        DateTime? outPutDay = outputDayOfOffset(
            currentDayOffset: currentDayOffset, diffOffset: diff);
        if (outPutDay == null) {
          return false;
        }
        final outputOffset = offsetOfDate(outPutDay);
        animateToDayOffset(outputOffset);
        if (this.widget.onScrolEnd != null) {
          this.widget.onScrolEnd!(outPutDay!);
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // we need to update the tasks list in case the tasks have changed
    return GestureDetector(
      child: Container(
        color: style.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SingleChildScrollView(
              controller: dayHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 60,
                  ),
                  for (int i = 0; i < config.totalDays; i++)
                    Stack(
                      children: [
                        (this.currentDayDistance == i)
                            ? Container(
                                height: 30,
                                width: (config.cellWidth ?? 0).toDouble(),
                                color: Color(0xFFF4F4F4),
                              )
                            : SizedBox.shrink(),
                        widget.headers[i]
                      ],
                    ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: style.dividerColor ?? Theme.of(context).primaryColor,
            ),
            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(
                                width: 1.0,
                                color: style.dividerColor ??
                                    Theme.of(context).primaryColor))),
                    width: 60,
                    child: Center(
                      child: Text('All Day'),
                    ),
                  ),
                  Flexible(
                      child: SingleChildScrollView(
                    controller: dayHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 34,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (int i = 0; i < config.totalDays; i++)
                            Stack(
                              children: [
                                (this.currentDayDistance == i)
                                    ? Container(
                                        height: 34,
                                        width:
                                            (config.cellWidth ?? 0).toDouble(),
                                        color: Color(0xFFF4F4F4),
                                      )
                                    : SizedBox.shrink(),
                                Container(
                                  height: 34,
                                  width: config.cellWidth?.toDouble() ?? 0,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: style.dividerColor ??
                                              Theme.of(context).primaryColor,
                                          width: 1)),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: (widget.alldayEvents[i])
                                          .map((e) => Column(
                                                children: [
                                                  SizedBox(
                                                    height: 8,
                                                  ),
                                                  Container(
                                                    height: 18,
                                                    width: config.cellWidth
                                                            ?.toDouble() ??
                                                        0.0,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8),
                                                    child: e.child ??
                                                        SizedBox.shrink(),
                                                  )
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ))
                ]),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: timeVerticalController,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              //first number is start hour and second number is end hour
                              for (int i = widget.startHour;
                                  i <= widget.endHour;
                                  i++)
                                Padding(
                                  // we need some additional padding horizontally if we're showing in am/pm format
                                  padding: EdgeInsets.symmetric(
                                    horizontal: !config.use24HourFormat ? 4 : 0,
                                  ),
                                  child: TimePlannerTime(
                                    // this returns the formatted time string based on the use24HourFormat argument.
                                    time: formattedTime(i),
                                    setTimeOnAxis: config.setTimeOnAxis,
                                  ),
                                )
                            ],
                          ),
                          Container(
                            height:
                                (config.totalHours * config.cellHeight!) + 80,
                            width: 1,
                            color: style.dividerColor ??
                                Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: buildMainBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMainBody() {
    final hour = hourRatioOfReserveBox(_reserveOffsetY);
    return GestureDetector(
        onLongPressStart: (details) {
          setState(() {
            _reserveOffsetY =
                details.localPosition.dy + mainVerticalController.offset;
            _displayReserve = true;
            offsetIndex = offsetXIndex(details.localPosition.dx);
          });
        },
        onLongPressEnd: (details) {
          setState(() {
            offsetIndex = offsetXIndex(details.localPosition.dx);
            _displayReserve = false;
            _reserveOffsetY =
                details.localPosition.dy + mainVerticalController.offset;
            if (this.widget.onReserveBoxSelected != null) {
              final startHour = formatTime(hour);
              final endHour = formatTime(hour + 1);
              DateTime todayOffset = this.widget.today;
              final diffIndex = this.currentDayDistance - offsetIndex;
              if (diffIndex > 0) {
                todayOffset =
                    this.widget.today.add(Duration(days: -(diffIndex.abs())));
              } else if (diffIndex < 0) {
                todayOffset =
                    this.widget.today.add(Duration(days: diffIndex.abs()));
              }
              final startTime = combineDateTime(todayOffset, startHour);
              final endTime = combineDateTime(todayOffset, endHour);
              print("StartDate: ${startTime} EndDate: ${endTime}");
              this.widget.onReserveBoxSelected!(startTime, endTime);
            }
          });
        },
        onLongPressMoveUpdate: (details) {
          setState(() {
            offsetIndex = offsetXIndex(details.localPosition.dx);
            _reserveOffsetY =
                details.localPosition.dy + mainVerticalController.offset;
          });
        },
        onLongPressDown: (details) {
          setState(() {
            offsetIndex = offsetXIndex(details.localPosition.dx);
            _reserveOffsetY =
                details.localPosition.dy + mainVerticalController.offset;
          });
        },
        child: SingleChildScrollView(
          controller: mainVerticalController,
          child: NotificationListener<ScrollNotification>(
              onNotification: onScrollNotification,
              child: SingleChildScrollView(
                controller: mainHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        StreamBuilder<List<TimePlannerTask>>(
                          stream: tasks,
                          builder: (context, snapshot) {
                            final tasks = snapshot.data ?? [];
                            return SizedBox(
                              height:
                                  (config.totalHours * config.cellHeight!) + 80,
                              width: (config.totalDays * config.cellWidth!)
                                  .toDouble(),
                              child: Stack(
                                children: <Widget>[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      for (var i = 0;
                                          i < config.totalHours;
                                          i++)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            SizedBox(
                                              height: (config.cellHeight! - 1)
                                                  .toDouble(),
                                            ),
                                            const Divider(
                                              height: 1,
                                            ),
                                          ],
                                        )
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      for (var i = 0; i < config.totalDays; i++)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            (this.currentDayDistance == i)
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      Container(
                                                        width:
                                                            ((config.cellWidth ??
                                                                        0) -
                                                                    1)
                                                                .toDouble(),
                                                        height: (config
                                                                    .totalHours *
                                                                config
                                                                    .cellHeight!) +
                                                            config.cellHeight!,
                                                        color:
                                                            Color(0xFFF4F4F4),
                                                      )
                                                    ],
                                                  )
                                                : SizedBox(
                                                    width:
                                                        (config.cellWidth! - 1)
                                                            .toDouble(),
                                                  ),
                                            Container(
                                              width: 1,
                                              height: (config.totalHours *
                                                      config.cellHeight!) +
                                                  config.cellHeight!,
                                              color: Colors.black12,
                                            )
                                          ],
                                        )
                                    ],
                                  ),
                                  for (int i = 0; i < tasks.length; i++)
                                    tasks[i],
                                  _displayReserve == true
                                      ? CurrentReservedEventBox(
                                          offsetXIndex: this.offsetIndex,
                                          todayIndex: this.currentDayDistance,
                                          cellWidth:
                                              config.cellWidth?.toDouble() ??
                                                  0.0,
                                          date: DateTime
                                              .now(), //this.widget..date,
                                          currentHour: hour,
                                          startTime: formatTime(hour),
                                          endTime: formatTime(hour + 1))
                                      : SizedBox.shrink()
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ));
  }

  String formatTime(double hour) {
    int hours = hour.floor();
    if (hours >= 24) {
      return '24:00';
    }
    int minutes = ((hour - hours) * 60).round();
    Duration duration = Duration(hours: hours, minutes: minutes);
    final finalDate = DateTime(0).add(duration);

    return '${finalDate.hour < 10 ? '0${finalDate.hour}' : finalDate.hour}:${finalDate.minute < 10 ? '0${finalDate.minute}' : finalDate.minute}';
  }

  int offsetXIndex(double positionX) {
    final offsetXIndex = (positionX + mainHorizontalController.offset) /
        (config.cellWidth ?? 1.0).toDouble();
    return offsetXIndex.toInt();
  }

  bool isSameDay({required DateTime? date1, required DateTime? date2}) {
    if (date1 == null) {
      return false;
    }
    if (date2 == null) {
      return false;
    }
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int adjustDouble(double number) {
    // Get the integer part of the number
    int intPart = number.floor();

    // Get the decimal part of the number
    double decimalPart = number - intPart;

    // Adjust the integer part based on the decimal part
    if (decimalPart >= 0.5) {
      return intPart + 1;
    } else {
      return intPart;
    }
  }

  DateTime? outputDayOfOffset(
      {required double currentDayOffset, double? diffOffset}) {
    final diff = diffOffset ??
        (currentDayOffset - (mainHorizontalController.offset - 60));

    final absDiff = diff.abs();
    final offsetOfDays = (absDiff / (config.cellWidth ?? 1));

    final days = adjustDouble(offsetOfDays);
    DateTime? outPutDay = null;

    if (diff < 0) {
      //To Right
      outPutDay = this.widget.currentDate.add(Duration(days: days));
    } else if ((diff > 0)) {
      //To Left
      outPutDay = this.widget.currentDate.add(Duration(days: -days));
    }
    return outPutDay;
  }

  double offsetOfDate(DateTime? dateTime) {
    final date = dateTime ?? this.widget.currentDate;

    final days = bloc
        .startOfDateTime(date)
        .difference(bloc.startOfDateTime(this.widget.range.start))
        .inDays;
    final currentDayOffset = (config.cellWidth?.toDouble() ?? 1) * days;
    return currentDayOffset;
  }

  String formattedTime(int hour) {
    /// this method formats the input hour into a time string
    /// modifing it as necessary based on the use24HourFormat flag .
    if (config.use24HourFormat) {
      // we use the hour as-is
      return hour.toString() + ':00';
    } else {
      // we format the time to use the am/pm scheme
      if (hour == 0) return "12:00 am";
      if (hour < 12) return "$hour:00 am";
      if (hour == 12) return "12:00 pm";
      return "${hour - 12}:00 pm";
    }
  }

  double hourRatioOfReserveBox(double offsetY) {
    final total = 24 * _hourOfheight;
    final initialY = offsetY - (minuteOfHour * defaultMinuteHeight) / 2;

    final relativeHour = 24 - ((total - initialY) / _hourOfheight);
    final diff = (relativeHour - relativeHour.toInt());

    if (relativeHour <= 16 / _hourOfheight) {
      return 0;
    }
    if (relativeHour >= 23) {
      return 23;
    }
    double result = 0;
    if (diff <= 0.25) {
      result = relativeHour.toInt().toDouble();
    }
    if (diff <= 0.75) {
      result = (relativeHour.toInt() + 0.5);
    } else {
      result = relativeHour.round().toDouble();
    }
    return result;
  }

  DateTime combineDateTime(DateTime baseDate, String timeString) {
    List<String> parts = timeString.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return baseDate.copyWith(hour: hours, minute: minutes);
  }
}

class CurrentReservedEventBox extends StatelessWidget {
  final DateTime date;
  final String startTime;
  final String endTime;
  final double currentHour;
  final double cellWidth;
  final int offsetXIndex;
  final int todayIndex;
  final _hourOfheight = minuteOfHour * defaultMinuteHeight;
  CurrentReservedEventBox(
      {Key? key,
      required this.date,
      required this.currentHour,
      required this.startTime,
      required this.endTime,
      required this.offsetXIndex,
      required this.todayIndex,
      required this.cellWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final left = (config.cellWidth ?? 0) * this.offsetXIndex;
    DateTime currentDate = this.date;
    final offset = this.todayIndex - this.offsetXIndex;
    if (offset > 0) {
      currentDate = this.date.add(Duration(days: -(offset.abs())));
    }
    if (offset < 0) {
      currentDate = this.date.add(Duration(days: offset.abs()));
    }
    return Positioned(
      top: currentHour * _hourOfheight,
      left: left.toDouble(),
      right: null,
      width: this.cellWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.95),
              border: Border.all(color: Color(0xFFE9E9E9), width: 1),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
              shape: BoxShape.rectangle),
          height: minuteOfHour * defaultMinuteHeight,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentDate.day}/${currentDate.month} ${getWeekdayName(currentDate.weekday)}',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.28,
                      color: Colors.white),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  '${startTime} → ${endTime}',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.28,
                      color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}
