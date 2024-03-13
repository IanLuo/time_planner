import 'package:flutter/material.dart';

class CalendarEvent {
  CalendarEvent({
    required this.eventName,
    required this.eventDate,
    required this.eventTextStyle,
    this.eventBackgroundColor = Colors.blue,
    this.eventTypeBorderColor,
    this.eventTypeColor,
    this.eventID,
  });

  final String eventName;
  final TextStyle eventTextStyle;
  final DateTime eventDate;
  final String? eventID;
  final Color eventBackgroundColor;
  final Color? eventTypeColor;
  final Color? eventTypeBorderColor;
}
