import 'package:flutter/material.dart';

/// A static demo task used exclusively for the onboarding sample schedule.
///
/// This is a plain Dart data class — NOT connected to the real tasks domain
/// model, NOT @freezed, NOT backed by any Riverpod provider or API call.
/// It exists solely to give new users an emotional preview of the app (UX-DR27).
class DemoTask {
  const DemoTask({
    required this.title,
    required this.scheduledTime,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  final String title;
  final TimeOfDay scheduledTime;
  final int durationMinutes;
  final bool isCompleted;
}

/// Static fixture of demo tasks shown during onboarding.
///
/// Written in first-person scheduling language using the "past self / future self"
/// warm narrative voice (UX-DR32).  One task is pre-completed to demonstrate
/// the "done" visual state.
///
/// No network calls, no Riverpod providers — load directly in [SampleScheduleStep].
const List<DemoTask> kDemoSchedule = [
  DemoTask(
    title: 'Review the project brief',
    scheduledTime: TimeOfDay(hour: 9, minute: 0),
    durationMinutes: 45,
  ),
  DemoTask(
    title: 'Call Mum back',
    scheduledTime: TimeOfDay(hour: 10, minute: 30),
    durationMinutes: 20,
    isCompleted: true,
  ),
  DemoTask(
    title: '30-minute walk',
    scheduledTime: TimeOfDay(hour: 12, minute: 30),
    durationMinutes: 30,
  ),
  DemoTask(
    title: 'Respond to team messages',
    scheduledTime: TimeOfDay(hour: 14, minute: 0),
    durationMinutes: 25,
  ),
  DemoTask(
    title: 'Prep for tomorrow',
    scheduledTime: TimeOfDay(hour: 17, minute: 0),
    durationMinutes: 20,
  ),
];
