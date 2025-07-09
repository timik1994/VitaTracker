import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsSection> createState() => _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState extends State<NotificationSettingsSection> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;

  // Время для старых периодов (утро, день, вечер, перед сном)
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _nightTime = const TimeOfDay(hour: 22, minute: 0);

  // Время для новых режимов (1, 2, 3 раза в день)
  TimeOfDay _onceTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _twiceTime1 = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _twiceTime2 = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _thriceTime1 = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _thriceTime2 = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _thriceTime3 = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    setState(() {
      _soundEnabled = notificationService.soundEnabled;
      _vibrationEnabled = notificationService.vibrationEnabled;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _morningTime = TimeOfDay(
        hour: prefs.getInt('morning_start_hour') ?? 8,
        minute: prefs.getInt('morning_start_minute') ?? 0,
      );
      _afternoonTime = TimeOfDay(
        hour: prefs.getInt('afternoon_start_hour') ?? 12,
        minute: prefs.getInt('afternoon_start_minute') ?? 0,
      );
      _eveningTime = TimeOfDay(
        hour: prefs.getInt('evening_start_hour') ?? 18,
        minute: prefs.getInt('evening_start_minute') ?? 0,
      );
      _nightTime = TimeOfDay(
        hour: prefs.getInt('bedtime_start_hour') ?? 22,
        minute: prefs.getInt('bedtime_start_minute') ?? 0,
      );
      _onceTime = TimeOfDay(
        hour: prefs.getInt('once_time_hour') ?? 8,
        minute: prefs.getInt('once_time_minute') ?? 0,
      );
      _twiceTime1 = TimeOfDay(
        hour: prefs.getInt('twice_time1_hour') ?? 8,
        minute: prefs.getInt('twice_time1_minute') ?? 0,
      );
      _twiceTime2 = TimeOfDay(
        hour: prefs.getInt('twice_time2_hour') ?? 18,
        minute: prefs.getInt('twice_time2_minute') ?? 0,
      );
      _thriceTime1 = TimeOfDay(
        hour: prefs.getInt('thrice_time1_hour') ?? 8,
        minute: prefs.getInt('thrice_time1_minute') ?? 0,
      );
      _thriceTime2 = TimeOfDay(
        hour: prefs.getInt('thrice_time2_hour') ?? 12,
        minute: prefs.getInt('thrice_time2_minute') ?? 0,
      );
      _thriceTime3 = TimeOfDay(
        hour: prefs.getInt('thrice_time3_hour') ?? 18,
        minute: prefs.getInt('thrice_time3_minute') ?? 0,
      );
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    if (!value) {
      await notificationService.cancelAllNotifications();
    } else {
      await notificationService.rescheduleAllNotifications();
    }
  }

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_start_hour', _morningTime.hour);
    await prefs.setInt('morning_start_minute', _morningTime.minute);
    await prefs.setInt('afternoon_start_hour', _afternoonTime.hour);
    await prefs.setInt('afternoon_start_minute', _afternoonTime.minute);
    await prefs.setInt('evening_start_hour', _eveningTime.hour);
    await prefs.setInt('evening_start_minute', _eveningTime.minute);
    await prefs.setInt('bedtime_start_hour', _nightTime.hour);
    await prefs.setInt('bedtime_start_minute', _nightTime.minute);
    await prefs.setInt('once_time_hour', _onceTime.hour);
    await prefs.setInt('once_time_minute', _onceTime.minute);
    await prefs.setInt('twice_time1_hour', _twiceTime1.hour);
    await prefs.setInt('twice_time1_minute', _twiceTime1.minute);
    await prefs.setInt('twice_time2_hour', _twiceTime2.hour);
    await prefs.setInt('twice_time2_minute', _twiceTime2.minute);
    await prefs.setInt('thrice_time1_hour', _thriceTime1.hour);
    await prefs.setInt('thrice_time1_minute', _thriceTime1.minute);
    await prefs.setInt('thrice_time2_hour', _thriceTime2.hour);
    await prefs.setInt('thrice_time2_minute', _thriceTime2.minute);
    await prefs.setInt('thrice_time3_hour', _thriceTime3.hour);
    await prefs.setInt('thrice_time3_minute', _thriceTime3.minute);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.rescheduleAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children:const [
                    Icon(Icons.notifications, color: Color(0xFF1976D2)),
                     SizedBox(width: 8),
                    Text('Уведомления', style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Включить уведомления'),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    await _setNotificationsEnabled(value);
                  },
                  activeColor: const Color(0xFF1976D2),
                ),
                SwitchListTile(
                  title: const Text('Звук'),
                  value: _soundEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) async {
                          setState(() => _soundEnabled = value);
                          await notificationService.setSoundEnabled(value);
                          await notificationService.rescheduleAllNotifications();
                        }
                      : null,
                  activeColor: const Color(0xFF1976D2),
                ),
                SwitchListTile(
                  title: const Text('Вибрация'),
                  value: _vibrationEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) async {
                          setState(() => _vibrationEnabled = value);
                          await notificationService.setVibrationEnabled(value);
                          await notificationService.rescheduleAllNotifications();
                        }
                      : null,
                  activeColor: const Color(0xFF1976D2),
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.access_time, color: Color(0xFF1976D2)),
                    SizedBox(width: 8),
                    Text('Временные интервалы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                // --- Периоды дня ---
                Row(
                  children: const [
                    Icon(Icons.wb_sunny, color: Color(0xFF1976D2)),
                     SizedBox(width: 8),
                    Text('Периоды дня', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTimePicker('Утро', _morningTime, (t) => setState(() { _morningTime = t; _saveTimes(); })),
                _buildTimePicker('День', _afternoonTime, (t) => setState(() { _afternoonTime = t; _saveTimes(); })),
                _buildTimePicker('Вечер', _eveningTime, (t) => setState(() { _eveningTime = t; _saveTimes(); })),
                _buildTimePicker('Перед сном', _nightTime, (t) => setState(() { _nightTime = t; _saveTimes(); })),
                const Divider(height: 24),
                // --- 1 раз в день ---
                Row(
                  children: const[
                    Icon(Icons.filter_1, color: Color(0xFF1976D2)),
                     SizedBox(width: 8),
                    Text('1 раз в день', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTimePicker('Время', _onceTime, (t) => setState(() { _onceTime = t; _saveTimes(); })),
                const Divider(height: 24),
                // --- 2 раза в день ---
                Row(
                  children: const [
                    Icon(Icons.filter_2, color: Color(0xFF1976D2)),
                     SizedBox(width: 8),
                    Text('2 раза в день', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTimePicker('Первый приём', _twiceTime1, (t) => setState(() { _twiceTime1 = t; _saveTimes(); })),
                _buildTimePicker('Второй приём', _twiceTime2, (t) => setState(() { _twiceTime2 = t; _saveTimes(); })),
                const Divider(height: 24),
                // --- 3 раза в день ---
                Row(
                  children: const[
                    Icon(Icons.filter_3, color: Color(0xFF1976D2)),
                     SizedBox(width: 8),
                    Text('3 раза в день', style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTimePicker('Первый приём', _thriceTime1, (t) => setState(() { _thriceTime1 = t; _saveTimes(); })),
                _buildTimePicker('Второй приём', _thriceTime2, (t) => setState(() { _thriceTime2 = t; _saveTimes(); })),
                _buildTimePicker('Третий приём', _thriceTime3, (t) => setState(() { _thriceTime3 = t; _saveTimes(); })),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: const BorderSide(color: Color(0xFF1976D2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
            label: Text(time.format(context), style: const TextStyle(fontSize: 16, color: Color(0xFF1976D2))),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      useMaterial3: false,
                    ),
                    child: Localizations.override(
                      context: context,
                      locale: const Locale('ru'),
                      delegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      child: child!,
                    ),
                  );
                },
                cancelText: 'Отмена',
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
          ),
        ],
      ),
    );
  }
} 