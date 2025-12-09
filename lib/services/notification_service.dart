import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();  // Changed back to DeviceInfoPlugin

  

  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      // Convert TimezoneInfo to String directly
      final location = tz.getLocation(timeZoneName.toString());
      tz.setLocalLocation(location);
    } catch (e) {
      debugPrint('Timezone error: $e → using UTC as fallback');
      tz.setLocalLocation(tz.UTC);
    }
  }
  Future<bool> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }
  Future<bool> _hasExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt < 31; // Return true for Android < 12
    }
    return true;
  }

  Future<void> scheduleServiceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      final hasPermission = await _requestNotificationPermission();
      if (!hasPermission) {
        throw Exception('Izin notifikasi tidak diizinkan');
      }
      await _scheduleExactNotification(id, title, body, when);
    } catch (e, stack) {
      debugPrint('Error scheduling exact notification: $e\n$stack');
      await _scheduleRegularNotification(id, title, body, when);
    }
  }

  Future<void> _scheduleExactNotification(
      int id,
      String title,
      String body,
      DateTime when,
      ) async {
    final tzDateTime = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'service_reminder',
          'Pengingat Servis',
          channelDescription: 'Pengingat untuk jadwal servis mobil Anda',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'service',
      // Remove the uiLocalNotificationDateInterpretation parameter as it's not needed here
    );
  }

  Future<void> _scheduleRegularNotification(
      int id,
      String title,
      String body,
      DateTime when,
      ) async {
    final tzDateTime = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'service_reminder',
          'Pengingat Servis',
          channelDescription: 'Pengingat untuk jadwal servis mobil Anda',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'service',
      androidScheduleMode: AndroidScheduleMode.inexact,  // Added this line
    );
  }
}