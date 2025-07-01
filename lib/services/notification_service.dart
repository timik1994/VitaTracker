import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/vitamin.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _repeatInterval = 30;
  String _selectedSound = 'Default';

  factory NotificationService() => _instance;

  NotificationService._internal();

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get repeatInterval => _repeatInterval;
  String get selectedSound => _selectedSound;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null && details.payload!.startsWith('confirm_')) {
          final parts = details.payload!.split('_');
          final id = int.tryParse(parts[1]);
          final result = parts.length > 2 ? parts[2] : 'accepted';
          if (id != null) {
            if (result == 'accepted') {
              await DatabaseService().updateVitaminIntakeAsTaken(id);
            } else {
              await DatabaseService().updateVitaminIntakeAsMissed(id);
            }
            await cancelNotification(id);
          }
        }
      },
    );

    // Запрос разрешений на уведомления
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestPermission();
    }
    
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Инициализация временных зон
    tz.initializeTimeZones();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('notification_sound') ?? true;
    _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
    _repeatInterval = prefs.getInt('notification_repeat_interval') ?? 30;
    _selectedSound = prefs.getString('notification_sound_file') ?? 'Default';
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_vibration', value);
    notifyListeners();
  }

  Future<void> setRepeatInterval(int value) async {
    _repeatInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_repeat_interval', value);
    notifyListeners();
  }

  Future<void> setSelectedSound(String soundName) async {
    _selectedSound = soundName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound_file', soundName);
    notifyListeners();
  }

  Future<void> scheduleVitaminNotificationWithInterval({
    required Vitamin vitamin,
    required int intakeId,
    required DateTime start,
    required DateTime end,
    Duration interval = const Duration(minutes: 10),
  }) async {
    // Отменяем предыдущие уведомления для этого приёма
    await cancelNotification(intakeId);

    DateTime nextTime = start;
    int notificationId = intakeId;

    // Получаем настройки временных промежутков
    final prefs = await SharedPreferences.getInstance();
    final morningStart = TimeOfDay(
      hour: prefs.getInt('morning_start_hour') ?? 8,
      minute: prefs.getInt('morning_start_minute') ?? 0,
    );
    final morningEnd = TimeOfDay(
      hour: prefs.getInt('morning_end_hour') ?? 10,
      minute: prefs.getInt('morning_end_minute') ?? 0,
    );
    final afternoonStart = TimeOfDay(
      hour: prefs.getInt('afternoon_start_hour') ?? 13,
      minute: prefs.getInt('afternoon_start_minute') ?? 0,
    );
    final afternoonEnd = TimeOfDay(
      hour: prefs.getInt('afternoon_end_hour') ?? 15,
      minute: prefs.getInt('afternoon_end_minute') ?? 0,
    );
    final eveningStart = TimeOfDay(
      hour: prefs.getInt('evening_start_hour') ?? 19,
      minute: prefs.getInt('evening_start_minute') ?? 0,
    );
    final eveningEnd = TimeOfDay(
      hour: prefs.getInt('evening_end_hour') ?? 21,
      minute: prefs.getInt('evening_end_minute') ?? 0,
    );

    print('Планирование уведомлений для витамина ${vitamin.name}');
    print('Временные промежутки:');
    print('Утро: ${morningStart.hour}:${morningStart.minute} - ${morningEnd.hour}:${morningEnd.minute}');
    print('День: ${afternoonStart.hour}:${afternoonStart.minute} - ${afternoonEnd.hour}:${afternoonEnd.minute}');
    print('Вечер: ${eveningStart.hour}:${eveningStart.minute} - ${eveningEnd.hour}:${eveningEnd.minute}');

    while (nextTime.isBefore(end)) {
      final timeOfDay = TimeOfDay(hour: nextTime.hour, minute: nextTime.minute);
      
      // Проверяем, попадает ли время в один из разрешенных промежутков
      bool isInAllowedPeriod = _isTimeInRange(timeOfDay, morningStart, morningEnd) ||
          _isTimeInRange(timeOfDay, afternoonStart, afternoonEnd) ||
          _isTimeInRange(timeOfDay, eveningStart, eveningEnd);

      if (isInAllowedPeriod) {
        final tzScheduled = tz.TZDateTime.from(nextTime, tz.local);
        print('Планирование уведомления на ${tzScheduled.toString()}');
        
        try {
          await _notifications.zonedSchedule(
            notificationId,
            'Время принять ${vitamin.name}! 💊',
            'Вы приняли витамин?',
            tzScheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'vitamin_reminders',
                'Напоминания о витаминах',
                importance: Importance.high,
                priority: Priority.high,
                actions: [
                  AndroidNotificationAction(
                    'accepted',
                    'Принял',
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'missed',
                    'Не принял',
                    showsUserInterface: true,
                  ),
                ],
                sound: _soundEnabled ? const RawResourceAndroidNotificationSound('notification') : null,
                enableVibration: _vibrationEnabled,
              ),
              iOS: DarwinNotificationDetails(
                sound: _soundEnabled ? 'notification.wav' : null,
                presentSound: _soundEnabled,
                presentBadge: true,
                presentAlert: true,
              ),
            ),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: null,
            payload: 'confirm_${intakeId}_accepted',
          );
          print('Уведомление успешно запланировано');
        } catch (e) {
          print('Ошибка при планировании уведомления: $e');
          // Если не удалось установить пользовательский звук, используем системный
          try {
            await _notifications.zonedSchedule(
              notificationId,
              'Время принять ${vitamin.name}! 💊',
              'Вы приняли витамин?',
              tzScheduled,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'vitamin_reminders',
                  'Напоминания о витаминах',
                  importance: Importance.high,
                  priority: Priority.high,
                  actions: [
                    AndroidNotificationAction(
                      'accepted',
                      'Принял',
                      showsUserInterface: true,
                    ),
                    AndroidNotificationAction(
                      'missed',
                      'Не принял',
                      showsUserInterface: true,
                    ),
                  ],
                  enableVibration: _vibrationEnabled,
                ),
                iOS: DarwinNotificationDetails(
                  presentSound: _soundEnabled,
                  presentBadge: true,
                  presentAlert: true,
                ),
              ),
              androidAllowWhileIdle: true,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: null,
              payload: 'confirm_${intakeId}_accepted',
            );
            print('Уведомление успешно запланировано с системным звуком');
          } catch (e) {
            print('Ошибка при планировании уведомления с системным звуком: $e');
          }
        }
        notificationId++;
      }
      nextTime = nextTime.add(interval);
    }
  }

  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;

    if (endInMinutes < startInMinutes) {
      // Если промежуток переходит через полночь
      return timeInMinutes >= startInMinutes || timeInMinutes <= endInMinutes;
    }
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    final dbService = DatabaseService();
    final now = DateTime.now();
    final intakes = await dbService.getVitaminIntakes();

    // Группируем приёмы по периоду суток
    Map<String, List<Vitamin>> periodVitamins = {
      'Утро': [],
      'День': [],
      'Вечер': [],
      'Перед сном': [],
    };
    final prefs = await SharedPreferences.getInstance();
    final periods = [
      {
        'name': 'Утро',
        'start': TimeOfDay(hour: prefs.getInt('morning_start_hour') ?? 8, minute: prefs.getInt('morning_start_minute') ?? 0),
        'end': TimeOfDay(hour: prefs.getInt('morning_end_hour') ?? 10, minute: prefs.getInt('morning_end_minute') ?? 0),
      },
      {
        'name': 'День',
        'start': TimeOfDay(hour: prefs.getInt('afternoon_start_hour') ?? 13, minute: prefs.getInt('afternoon_start_minute') ?? 0),
        'end': TimeOfDay(hour: prefs.getInt('afternoon_end_hour') ?? 15, minute: prefs.getInt('afternoon_end_minute') ?? 0),
      },
      {
        'name': 'Вечер',
        'start': TimeOfDay(hour: prefs.getInt('evening_start_hour') ?? 19, minute: prefs.getInt('evening_start_minute') ?? 0),
        'end': TimeOfDay(hour: prefs.getInt('evening_end_hour') ?? 21, minute: prefs.getInt('evening_end_minute') ?? 0),
      },
      {
        'name': 'Перед сном',
        'start': TimeOfDay(hour: prefs.getInt('bedtime_start_hour') ?? 22, minute: prefs.getInt('bedtime_start_minute') ?? 0),
        'end': TimeOfDay(hour: prefs.getInt('bedtime_end_hour') ?? 23, minute: prefs.getInt('bedtime_end_minute') ?? 59),
      },
    ];

    for (final intake in intakes) {
      if (intake.isTaken || intake.scheduledTime.isBefore(now)) continue;
      final vitamin = await dbService.getVitamins().then((vits) => vits.firstWhere((v) => v.id == intake.vitaminId));
      final time = TimeOfDay(hour: intake.scheduledTime.hour, minute: intake.scheduledTime.minute);
      for (final period in periods) {
        if (_isTimeInRange(time, period['start'] as TimeOfDay, period['end'] as TimeOfDay)) {
          periodVitamins[period['name'] as String]?.add(vitamin);
          break;
        }
      }
    }

    int notificationId = 10000; // уникальный id для групповых уведомлений
    for (final period in periods) {
      final name = period['name'] as String;
      final vitamins = periodVitamins[name]!;
      if (vitamins.isEmpty) continue;
      final nowDate = DateTime.now();
      final scheduledTime = DateTime(nowDate.year, nowDate.month, nowDate.day, (period['start'] as TimeOfDay).hour, (period['start'] as TimeOfDay).minute);
      final tzScheduled = tz.TZDateTime.from(scheduledTime.isAfter(nowDate) ? scheduledTime : scheduledTime.add(const Duration(days: 1)), tz.local);
      final vitaminNames = vitamins.map((v) => v.name).join(', ');
      await _notifications.zonedSchedule(
        notificationId,
        'Время принять витамины ($name)! 💊',
        'Не забудьте принять: $vitaminNames',
        tzScheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vitamin_reminders',
            'Напоминания о витаминах',
            importance: Importance.high,
            priority: Priority.high,
            sound: _soundEnabled ? const RawResourceAndroidNotificationSound('notification') : null,
            enableVibration: _vibrationEnabled,
          ),
          iOS: DarwinNotificationDetails(
            sound: _soundEnabled ? 'notification.wav' : null,
            presentSound: _soundEnabled,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'group_period_${name}',
      );
      notificationId++;
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> updateVitaminIntakeAsMissed(int intakeId) async {
    final db = await DatabaseService().database;
    await db.update(
      'vitamin_intakes',
      {
        'isTaken': 0,
        'takenTime': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [intakeId],
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
} 