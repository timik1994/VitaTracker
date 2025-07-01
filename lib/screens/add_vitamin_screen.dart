import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vitamin.dart';
import '../models/vitamin_presets.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/gradient_button.dart';
import '../models/vitamin_intake.dart';
import 'package:flutter/cupertino.dart';
import '../components/my_dropdown.dart';
import '../components/my_segmented_button.dart';
import '../components/my_app_bar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddVitaminScreen extends StatefulWidget {
  final Vitamin? vitamin;
  const AddVitaminScreen({super.key, this.vitamin});

  @override
  State<AddVitaminScreen> createState() => _AddVitaminScreenState();
}

class _AddVitaminScreenState extends State<AddVitaminScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVitamin;
  String _form = 'Таблетки';
  String _unit = 'таблетка';
  String _period = 'утро';
  String _mealRelation = 'во время еды';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _description = '';
  String _benefits = '';
  String _organs = '';
  String _dailyNorm = '';
  String _bestTimeToTake = '';
  int _courseDays = 30;
  int _dosageValue = 1;

  final List<String> _forms = ['Таблетки', 'Капсулы', 'Порошок', 'Жидкость', 'Спрей', 'Саше'];
  final List<String> _periods = ['утро', 'день', 'вечер', 'перед сном'];
  final Map<String, IconData> _periodIcons = {
    'утро': Icons.wb_sunny_outlined,
    'день': Icons.brightness_5_outlined,
    'вечер': Icons.nights_stay_outlined,
    'перед сном': Icons.bedtime_outlined,
  };
  final List<String> _mealRelations = ['до еды', 'во время еды', 'после еды'];
  final Map<String, IconData> _mealRelationIcons = {
    'до еды': Icons.restaurant_menu,
    'во время еды': Icons.restaurant,
    'после еды': Icons.local_restaurant,
  };
  Set<String> _selectedPeriods = {'утро'};

  // Контроллеры для полей
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _compatibleController = TextEditingController();
  final TextEditingController _incompatibleController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();
  Color _customColor = Colors.blue;
  String _autoAbbreviation = '';
  Color _autoColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.vitamin != null) {
      _selectedVitamin = widget.vitamin!.name;
      _form = widget.vitamin!.form ?? 'Таблетки';
      _unit = widget.vitamin!.unit;
      _period = widget.vitamin!.period;
      _mealRelation = widget.vitamin!.mealRelation;
      _startDate = widget.vitamin!.startDate;
      _endDate = widget.vitamin!.endDate;
      _description = widget.vitamin!.description;
      _benefits = widget.vitamin!.benefits;
      _organs = widget.vitamin!.organs;
      _dailyNorm = widget.vitamin!.dailyNorm;
      _bestTimeToTake = widget.vitamin!.bestTimeToTake ?? '';
      _dosageController.text = widget.vitamin!.dosage.toString();
      _compatibleController.text = widget.vitamin!.compatibleWith.join(', ');
      _incompatibleController.text = widget.vitamin!.incompatibleWith.join(', ');
      _courseDays = widget.vitamin!.endDate.difference(widget.vitamin!.startDate).inDays + 1;
      _dosageValue = widget.vitamin!.dosage.toInt();
    }
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _compatibleController.dispose();
    _incompatibleController.dispose();
    _customNameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  void _updateFieldsFromPreset(String vitaminName) {
    final preset = vitaminPresets.firstWhere((v) => v.name == vitaminName);
    setState(() {
      _form = _forms.contains(preset.form) ? preset.form! : _forms.first;
      _unit = preset.unit;
      _period = _periods.contains(preset.period) ? preset.period : _periods.first;
      _mealRelation = _mealRelations.contains(preset.mealRelation) ? preset.mealRelation : _mealRelations.first;
      _description = preset.description;
      _benefits = preset.benefits;
      _organs = preset.organs;
      _dailyNorm = preset.dailyNorm;
      _bestTimeToTake = preset.bestTimeToTake ?? '';
      _dosageController.text = preset.dosage.toString();
      _compatibleController.text = preset.compatibleWith.join(', ');
      _incompatibleController.text = preset.incompatibleWith.join(', ');
    });
  }

  int get _selectedPeriodIndex => _periods.indexOf(_period);
  int get _selectedMealIndex => _mealRelations.indexOf(_mealRelation);

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vitaminItems = vitaminPresets.map((v) => v.name).toList() + ['Другое'];
    if (_selectedVitamin != null && !vitaminItems.contains(_selectedVitamin)) {
      _selectedVitamin = null;
    }

    return Scaffold(
      appBar: MyAppBar(
        showBackButton: true,
        title: widget.vitamin == null ? 'Добавить витамин' : 'Редактировать витамин',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор витамина через MyDropdown (в самом верху)
              MyDropdown<String>(
                value: vitaminItems.contains(_selectedVitamin) ? _selectedVitamin : null,
                items: vitaminItems,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    if (newValue == 'Другое') {
                      setState(() {
                        _selectedVitamin = 'Другое';
                        _customNameController.text = '';
                        _autoAbbreviation = '';
                        _autoColor = _getRandomColor();
                      });
                    } else {
                      setState(() {
                        _selectedVitamin = newValue;
                        _updateFieldsFromPreset(newValue);
                      });
                    }
                  }
                },
                itemLabel: (name) {
                  if (name == 'Другое') {
                    return Row(
                      children: [
                        Icon(Icons.add, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Другое', style: TextStyle(fontSize: 16)),
                      ],
                    );
                  }
                  final preset = vitaminPresets.firstWhere((v) => v.name == name);
                  return Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(preset.color),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(right: 12),
                        child: Text(
                          preset.abbreviation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
                hint: 'Выберите витамин',
              ),
              const SizedBox(height: 20),

              if (_selectedVitamin == 'Другое') ...[
                const SizedBox(height: 12),
                Text('Название', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customNameController,
                  onChanged: (value) {
                    setState(() {
                      _autoAbbreviation = _generateConsonantAbbreviation(value);
                    });
                  },
                  decoration: InputDecoration(hintText: 'Введите название'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Аббревиатура: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_autoAbbreviation, style: TextStyle(fontWeight: FontWeight.bold, color: _autoColor)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () async {
                        final color = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Выберите цвет'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: _autoColor,
                                onColorChanged: (color) {
                                  Navigator.of(context).pop(color);
                                },
                              ),
                            ),
                          ),
                        );
                        if (color != null) {
                          setState(() {
                            _autoColor = color;
                          });
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _autoColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.color_lens, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Форма выпуска
              const Text('Форма выпуска', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              MyDropdown<String>(
                value: _form,
                items: _forms,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _form = newValue;
                    });
                  }
                },
                itemLabel: (form) => Text(form),
                hint: 'Форма выпуска',
              ),
              const SizedBox(height: 20),

              // Дозировка (поле)
              const Text('Дозировка', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dosageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Дозировка',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(_unit, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Курс приёма (счётчик)
              const Text('Курс приёма (в днях)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      onPressed: _courseDays > 1
                          ? () => setState(() => _courseDays--)
                          : null,
                    ),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          '$_courseDays',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      onPressed: _courseDays < 365
                          ? () => setState(() => _courseDays++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Даты начала и окончания (компактно в ряд)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            _endDate = date.add(Duration(days: _courseDays));
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Начало: ${_formatShortDate(_startDate)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Окончание: ${_formatShortDate(_endDate)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Период приема (выбор через иконки с множественным выбором)
              const Text('Период приёма', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _periods.map((p) => Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedPeriods.contains(p)) {
                          if (_selectedPeriods.length > 1) {
                            _selectedPeriods.remove(p);
                          }
                        } else {
                          _selectedPeriods.add(p);
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedPeriods.contains(p) 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _periodIcons[p],
                            color: _selectedPeriods.contains(p) 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                            size: 28
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedPeriods.contains(p) 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                            fontWeight: _selectedPeriods.contains(p) 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Связь с едой (выбор через иконки)
              const Text('Связь с едой', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _mealRelations.map((m) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mealRelation = m),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _mealRelation == m 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _mealRelationIcons[m],
                            color: _mealRelation == m 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                            size: 28
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mealRelation == m 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                            fontWeight: _mealRelation == m 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Совместимость
              const Text(
                'Совместимость',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedVitamin != 'Другое') ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    controller: _compatibleController,
                    decoration: const InputDecoration(
                      hintText: 'Совместим с (через запятую)',
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    controller: _incompatibleController,
                    decoration: const InputDecoration(
                      hintText: 'Не совместим с (через запятую)',
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.light
                          ? [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ]
                          : [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                            ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black.withOpacity(0.10)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _saveVitamin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            widget.vitamin == null ? 'Добавить' : 'Сохранить',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onPrimary,
                             // fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveVitamin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVitamin == null) return;

    try {
      if (!mounted) return;
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final now = DateTime.now();

      // Проверка на дубликаты
      if (widget.vitamin == null) {
        final existing = (await dbService.getVitamins()).any((v) => v.name == _selectedVitamin);
        if (existing) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Такой витамин уже есть в списке!'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      Vitamin vitamin;
      if (_selectedVitamin == 'Другое') {
        vitamin = Vitamin(
          id: widget.vitamin?.id,
          name: _customNameController.text.trim(),
          abbreviation: _autoAbbreviation,
          dosage: double.tryParse(_dosageController.text) ?? 0,
          startDate: _startDate,
          endDate: _startDate.add(Duration(days: _courseDays - 1)),
          unit: _unit,
          color: _autoColor.value,
          period: _selectedPeriods.join(', '),
          mealRelation: _mealRelation,
          compatibleWith: [],
          incompatibleWith: [],
          description: _description,
          benefits: _benefits,
          organs: _organs,
          dailyNorm: _dailyNorm,
          bestTimeToTake: _bestTimeToTake,
          form: _form,
        );
      } else {
        final preset = vitaminPresets.firstWhere((v) => v.name == _selectedVitamin);
        vitamin = Vitamin(
          id: widget.vitamin?.id,
          name: _selectedVitamin!,
          abbreviation: preset.abbreviation,
          dosage: double.tryParse(_dosageController.text) ?? 0,
          startDate: _startDate,
          endDate: _startDate.add(Duration(days: _courseDays - 1)),
          unit: _unit,
          color: preset.color,
          period: _selectedPeriods.join(', '),
          mealRelation: _mealRelation,
          compatibleWith: _compatibleController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          incompatibleWith: _incompatibleController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          description: _description,
          benefits: _benefits,
          organs: _organs,
          dailyNorm: _dailyNorm,
          bestTimeToTake: _bestTimeToTake,
          form: _form,
        );
      }

      if (widget.vitamin != null) {
        // Редактирование
        await dbService.deleteVitamin(vitamin.id!);
        await dbService.insertVitamin(vitamin);
      } else {
        // Добавление
        final vitaminId = await dbService.insertVitamin(vitamin);
        // Создание приёмов и уведомлений — в фоне, чтобы не блокировать UI
        Future(() async {
          final periods = await dbService.getPeriodTimes();
          final period = periods[_period] ?? {'start': 7 * 60, 'end': 9 * 60};
          final startMinutes = period['start']!;
          final endMinutes = period['end']!;
          final todayStart = DateTime(now.year, now.month, now.day);
          final duration = _courseDays;
          final timesPerDay = _period == '3 раза в сутки' ? 3 : 1;

          for (int i = 0; i < duration; i++) {
            final day = todayStart.add(Duration(days: i));
            for (int t = 0; t < timesPerDay; t++) {
              final interval = ((endMinutes - startMinutes) ~/ timesPerDay);
              final minutes = startMinutes + interval * t;
              final start = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
              final end = DateTime(day.year, day.month, day.day, (minutes + interval) ~/ 60, (minutes + interval) % 60);
              if (start.isBefore(now)) continue;
              final intakeId = await dbService.insertVitaminIntake(VitaminIntake(
                vitaminId: vitaminId,
                scheduledTime: start,
                takenTime: DateTime.now(),
                isTaken: false,
              ));
              await notificationService.scheduleVitaminNotificationWithInterval(
                vitamin: vitamin,
                intakeId: intakeId,
                start: start,
                end: end,
                interval: const Duration(minutes: 10),
              );
            }
          }
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Витамин успешно сохранён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRandomColor() {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.cyan, Colors.indigo];
    colors.shuffle();
    return colors.first;
  }

  String _generateConsonantAbbreviation(String value) {
    final consonants = 'бвгджзйклмнпрстфхцчшщ';
    final chars = value
        .toLowerCase()
        .runes
        .map((r) => String.fromCharCode(r))
        .where((c) => consonants.contains(c) || 'bcdfghjklmnpqrstvwxyz'.contains(c))
        .toList();
    if (chars.isEmpty) return '';
    if (chars.length == 1) return chars.first.toUpperCase();
    return (chars.first + chars.last).toUpperCase();
  }
} 