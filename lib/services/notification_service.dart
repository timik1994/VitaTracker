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

  Future<void> scheduleVitaminNotificationExactTime({
    required Vitamin vitamin,
    required int intakeId,
    required DateTime scheduledTime,
  }) async {
    await cancelNotification(intakeId);
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
    try {
      await _notifications.zonedSchedule(
        intakeId,
        'Время стать лучше. Быстрее принимай витамин',
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
    } catch (e) {
      // fallback без звука
      await _notifications.zonedSchedule(
        intakeId,
        'Время стать лучше. Быстрее принимай витамины 💊',
        'Вы приняли витамин?',
        tzScheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vitamin_reminders',
            'Напоминания о витаминах',
            importance: Importance.high,
            priority: Priority.high,
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
    }
  }

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    final dbService = DatabaseService();
    final prefs = await SharedPreferences.getInstance();
    final intakes = await dbService.getVitaminIntakes();
    final vitamins = await dbService.getVitamins();
    for (final intake in intakes) {
      if (intake.isTaken) continue;
      Vitamin? vitamin;
      try {
        vitamin = vitamins.firstWhere((v) => v.id == intake.vitaminId);
      } catch (_) {
        vitamin = null;
      }
      if (vitamin == null) continue;
      // Определяем режим для витамина (утро, день, вечер, перед сном, 1/2/3 раза)
      // Здесь предполагается, что intake.scheduledTime уже содержит нужное время
      await scheduleVitaminNotificationExactTime(
        vitamin: vitamin,
        intakeId: intake.id!,
        scheduledTime: intake.scheduledTime,
      );
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