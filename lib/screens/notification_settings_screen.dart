import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../components/my_segmented_button.dart';
import '../components/my_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _hasChanges = false;
  
  // Сохраняем начальные значения для возможности отката
  late bool _initialSoundEnabled;
  late bool _initialVibrationEnabled;
  late TimeOfDay _initialMorningStart;
  late TimeOfDay _initialMorningEnd;
  late TimeOfDay _initialAfternoonStart;
  late TimeOfDay _initialAfternoonEnd;
  late TimeOfDay _initialEveningStart;
  late TimeOfDay _initialEveningEnd;
  late TimeOfDay _initialBedtimeStart;
  late TimeOfDay _initialBedtimeEnd;

  // Временные промежутки для уведомлений
  TimeOfDay _morningStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _morningEnd = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _afternoonStart = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _afternoonEnd = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _eveningStart = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _eveningEnd = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _bedtimeStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _bedtimeEnd = const TimeOfDay(hour: 23, minute: 59);

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
      
      // Сохраняем начальные значения
      _initialSoundEnabled = _soundEnabled;
      _initialVibrationEnabled = _vibrationEnabled;
      
      // Загрузка временных промежутков
      _morningStart = TimeOfDay(
        hour: prefs.getInt('morning_start_hour') ?? 8,
        minute: prefs.getInt('morning_start_minute') ?? 0,
      );
      _morningEnd = TimeOfDay(
        hour: prefs.getInt('morning_end_hour') ?? 10,
        minute: prefs.getInt('morning_end_minute') ?? 0,
      );
      _afternoonStart = TimeOfDay(
        hour: prefs.getInt('afternoon_start_hour') ?? 13,
        minute: prefs.getInt('afternoon_start_minute') ?? 0,
      );
      _afternoonEnd = TimeOfDay(
        hour: prefs.getInt('afternoon_end_hour') ?? 15,
        minute: prefs.getInt('afternoon_end_minute') ?? 0,
      );
      _eveningStart = TimeOfDay(
        hour: prefs.getInt('evening_start_hour') ?? 19,
        minute: prefs.getInt('evening_start_minute') ?? 0,
      );
      _eveningEnd = TimeOfDay(
        hour: prefs.getInt('evening_end_hour') ?? 21,
        minute: prefs.getInt('evening_end_minute') ?? 0,
      );
      _bedtimeStart = TimeOfDay(
        hour: prefs.getInt('bedtime_start_hour') ?? 22,
        minute: prefs.getInt('bedtime_start_minute') ?? 0,
      );
      _bedtimeEnd = TimeOfDay(
        hour: prefs.getInt('bedtime_end_hour') ?? 23,
        minute: prefs.getInt('bedtime_end_minute') ?? 59,
      );

      // Сохраняем начальные значения временных промежутков
      _initialMorningStart = _morningStart;
      _initialMorningEnd = _morningEnd;
      _initialAfternoonStart = _afternoonStart;
      _initialAfternoonEnd = _afternoonEnd;
      _initialEveningStart = _eveningStart;
      _initialEveningEnd = _eveningEnd;
      _initialBedtimeStart = _bedtimeStart;
      _initialBedtimeEnd = _bedtimeEnd;
    });
  }

  void _checkForChanges() {
    bool hasChanges = _soundEnabled != _initialSoundEnabled ||
        _vibrationEnabled != _initialVibrationEnabled ||
        _morningStart != _initialMorningStart ||
        _morningEnd != _initialMorningEnd ||
        _afternoonStart != _initialAfternoonStart ||
        _afternoonEnd != _initialAfternoonEnd ||
        _eveningStart != _initialEveningStart ||
        _eveningEnd != _initialEveningEnd ||
        _bedtimeStart != _initialBedtimeStart ||
        _bedtimeEnd != _initialBedtimeEnd;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveAndExit() async {
    // Сначала закрываем экран
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // Затем сохраняем настройки в фоновом режиме
    final prefs = await SharedPreferences.getInstance();
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    await notificationService.setSoundEnabled(_soundEnabled);
    await notificationService.setVibrationEnabled(_vibrationEnabled);
    
    // Сохранение временных промежутков
    await prefs.setInt('morning_start_hour', _morningStart.hour);
    await prefs.setInt('morning_start_minute', _morningStart.minute);
    await prefs.setInt('morning_end_hour', _morningEnd.hour);
    await prefs.setInt('morning_end_minute', _morningEnd.minute);
    await prefs.setInt('afternoon_start_hour', _afternoonStart.hour);
    await prefs.setInt('afternoon_start_minute', _afternoonStart.minute);
    await prefs.setInt('afternoon_end_hour', _afternoonEnd.hour);
    await prefs.setInt('afternoon_end_minute', _afternoonEnd.minute);
    await prefs.setInt('evening_start_hour', _eveningStart.hour);
    await prefs.setInt('evening_start_minute', _eveningStart.minute);
    await prefs.setInt('evening_end_hour', _eveningEnd.hour);
    await prefs.setInt('evening_end_minute', _eveningEnd.minute);
    await prefs.setInt('bedtime_start_hour', _bedtimeStart.hour);
    await prefs.setInt('bedtime_start_minute', _bedtimeStart.minute);
    await prefs.setInt('bedtime_end_hour', _bedtimeEnd.hour);
    await prefs.setInt('bedtime_end_minute', _bedtimeEnd.minute);

    // Перепланируем все уведомления с новыми настройками
    await notificationService.rescheduleAllNotifications();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        content: const Text('У вас есть несохраненные изменения. Хотите их сохранить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Не сохранять'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Сначала закрываем экран
      Navigator.of(context).pop();
      
      // Затем сохраняем настройки в фоновом режиме
      final prefs = await SharedPreferences.getInstance();
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await notificationService.setSoundEnabled(_soundEnabled);
      await notificationService.setVibrationEnabled(_vibrationEnabled);
      
      // Сохранение временных промежутков
      await prefs.setInt('morning_start_hour', _morningStart.hour);
      await prefs.setInt('morning_start_minute', _morningStart.minute);
      await prefs.setInt('morning_end_hour', _morningEnd.hour);
      await prefs.setInt('morning_end_minute', _morningEnd.minute);
      await prefs.setInt('afternoon_start_hour', _afternoonStart.hour);
      await prefs.setInt('afternoon_start_minute', _afternoonStart.minute);
      await prefs.setInt('afternoon_end_hour', _afternoonEnd.hour);
      await prefs.setInt('afternoon_end_minute', _afternoonEnd.minute);
      await prefs.setInt('evening_start_hour', _eveningStart.hour);
      await prefs.setInt('evening_start_minute', _eveningStart.minute);
      await prefs.setInt('evening_end_hour', _eveningEnd.hour);
      await prefs.setInt('evening_end_minute', _eveningEnd.minute);
      await prefs.setInt('bedtime_start_hour', _bedtimeStart.hour);
      await prefs.setInt('bedtime_start_minute', _bedtimeStart.minute);
      await prefs.setInt('bedtime_end_hour', _bedtimeEnd.hour);
      await prefs.setInt('bedtime_end_minute', _bedtimeEnd.minute);

      // Перепланируем все уведомления с новыми настройками
      await notificationService.rescheduleAllNotifications();
    } else if (result == false) {
      // Восстанавливаем начальные значения
      setState(() {
        _soundEnabled = _initialSoundEnabled;
        _vibrationEnabled = _initialVibrationEnabled;
        _morningStart = _initialMorningStart;
        _morningEnd = _initialMorningEnd;
        _afternoonStart = _initialAfternoonStart;
        _afternoonEnd = _initialAfternoonEnd;
        _eveningStart = _initialEveningStart;
        _eveningEnd = _initialEveningEnd;
        _bedtimeStart = _initialBedtimeStart;
        _bedtimeEnd = _initialBedtimeEnd;
      });
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: MyAppBar(
          title: 'Настройки уведомлений',
          showBackButton: true,
          onBackPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            // карточка основных настроек
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Основные настройки',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // переключатель звука
                    SwitchListTile(
                      title: const Text('Звук'),
                      value: _soundEnabled,
                      onChanged: (value) async {
                        setState(() => _soundEnabled = value);
                        await notificationService.setSoundEnabled(value);
                        _checkForChanges();
                      },
                    ),

                    // переключатель вибрации
                    SwitchListTile(
                      title: const Text('Вибрация'),
                      value: _vibrationEnabled,
                      onChanged: (value) async {
                        setState(() => _vibrationEnabled = value);
                        await notificationService.setVibrationEnabled(value);
                        _checkForChanges();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // карточка временных промежутков
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Временные промежутки',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeRangeSelector(
                      'Утро',
                      _morningStart,
                      _morningEnd,
                      (isStart) => _selectTime(context, isStart, 'morning'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeRangeSelector(
                      'День',
                      _afternoonStart,
                      _afternoonEnd,
                      (isStart) => _selectTime(context, isStart, 'afternoon'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeRangeSelector(
                      'Вечер',
                      _eveningStart,
                      _eveningEnd,
                      (isStart) => _selectTime(context, isStart, 'evening'),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeRangeSelector(
                      'Перед сном',
                      _bedtimeStart,
                      _bedtimeEnd,
                      (isStart) => _selectTime(context, isStart, 'bedtime'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _hasChanges ? _saveAndExit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(
    String title,
    TimeOfDay start,
    TimeOfDay end,
    Function(bool) onTimeSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onTimeSelected(true),
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('—'),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onTimeSelected(false),
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart, String period) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (period == 'morning' ? _morningStart : period == 'afternoon' ? _afternoonStart : period == 'evening' ? _eveningStart : _bedtimeStart)
          : (period == 'morning' ? _morningEnd : period == 'afternoon' ? _afternoonEnd : period == 'evening' ? _eveningEnd : _bedtimeEnd),
    );
    
    if (picked != null) {
      setState(() {
        if (period == 'morning') {
          if (isStart) _morningStart = picked;
          else _morningEnd = picked;
        } else if (period == 'afternoon') {
          if (isStart) _afternoonStart = picked;
          else _afternoonEnd = picked;
        } else if (period == 'evening') {
          if (isStart) _eveningStart = picked;
          else _eveningEnd = picked;
        } else {
          if (isStart) _bedtimeStart = picked;
          else _bedtimeEnd = picked;
        }
      });
      _checkForChanges();
    }
  }
} 