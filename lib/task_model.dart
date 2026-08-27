import 'package:flutter/material.dart';

class Task {
  String title;
  String description;
  DateTime dateTime;
  bool isHighPriority;
  bool isDone;

  Task({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.isHighPriority,
    this.isDone=false,

  });
}
