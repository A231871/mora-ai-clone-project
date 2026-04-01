import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Optional payload handling
      },
    );
  }

  Future<void> requestPermissions() async {
    // Basic permissions query
    await Permission.notification.request();
    
    // Explicit API requests for Local Notifications payload features on 13+
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int getNotificationId(String mongoId, [int dayOffset = 0]) {
    // 32-bit int safe hash. Using bitwise AND to prevent overflow
    return (mongoId.hashCode & 0x7FFFFFFF) + dayOffset;
  }

  int _mapDayToIso(String dayName) {
    switch (dayName.substring(0, 3).toLowerCase()) {
      case 'mon': return DateTime.monday;
      case 'tue': return DateTime.tuesday;
      case 'wed': return DateTime.wednesday;
      case 'thu': return DateTime.thursday;
      case 'fri': return DateTime.friday;
      case 'sat': return DateTime.saturday;
      case 'sun': return DateTime.sunday;
      default: return DateTime.monday;
    }
  }

  DateTime _nextInstanceOf(DateTime time, int targetWeekday) {
    DateTime scheduledDate = time;
    while (scheduledDate.weekday != targetWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleReminderNotification({
    required String mongoId,
    required String title,
    required String body,
    required DateTime time,
    required List<String> daysOfWeek,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mora_ai_reminders',
      'Shizuki Reminders',
      channelDescription: 'Alarm notifications for scheduled tasks.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (daysOfWeek.isEmpty) {
      // One-time reminder
      if (time.isBefore(DateTime.now())) return;
      int id = getNotificationId(mongoId, 0);
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(time, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // Recurring reminders for specified days
      for (int i = 0; i < daysOfWeek.length; i++) {
        int targetWeekday = _mapDayToIso(daysOfWeek[i]);
        DateTime nextInstance = _nextInstanceOf(time, targetWeekday);
        if (nextInstance.isBefore(DateTime.now())) {
          nextInstance = nextInstance.add(const Duration(days: 7));
        }

        int id = getNotificationId(mongoId, targetWeekday);
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(nextInstance, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancelReminderNotifications(String mongoId, {List<String>? previousDaysOfWeek}) async {
    await _notificationsPlugin.cancel(id: getNotificationId(mongoId, 0));
    
    if (previousDaysOfWeek != null && previousDaysOfWeek.isNotEmpty) {
      for (String day in previousDaysOfWeek) {
        int targetWeekday = _mapDayToIso(day);
        await _notificationsPlugin.cancel(id: getNotificationId(mongoId, targetWeekday));
      }
    } else {
      // Safely try cancelling all 7 possible days if unknown
      for (int i = 1; i <= 7; i++) {
        await _notificationsPlugin.cancel(id: getNotificationId(mongoId, i));
      }
    }
  }
}