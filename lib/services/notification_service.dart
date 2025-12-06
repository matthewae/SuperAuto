import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error setting local timezone: $e. Falling back to UTC.');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> scheduleServiceReminder(
      {required int id,
      required String title,
      required String body,
      required DateTime when}) async {
    // tz_data.initializeTimeZones(); // Dihapus karena sudah diinisialisasi di init()
    // tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone())); // Dihapus karena sudah diinisialisasi di init()
    await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'service_reminder',
            'Pengingat Servis',
            channelDescription: 'Pengingat untuk jadwal servis mobil Anda',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // androidAllowWhileIdle: true,
        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: 'service',
    );
  }
}