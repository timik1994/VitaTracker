import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vitamin.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'add_vitamin_screen.dart';
import 'settings_screen.dart';
import '../models/vitamin_intake.dart';
import '../components/my_app_bar.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<List<Vitamin>> _vitaminsFuture;

  @override
  void initState() {
    super.initState();
    _loadVitamins();
  }

  void _loadVitamins() {
    _vitaminsFuture =
        Provider.of<DatabaseService>(context, listen: false).getVitamins();
  }

  void refresh() {
    _loadVitamins();
    setState(() {});
  }

  Future<void> _markTodayIntakeAsTaken(int vitaminId) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final intakes = await dbService.getVitaminIntakes();
    VitaminIntake? todayIntake;
    try {
      todayIntake = intakes.firstWhere(
        (i) =>
            i.vitaminId == vitaminId &&
            i.scheduledTime
                .isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            i.scheduledTime.isBefore(todayEnd),
      );
    } catch (_) {
      todayIntake = null;
    }
    if (todayIntake == null) {
      // Если приёма нет — создаём и сразу отмечаем как принятый
      final intake = VitaminIntake(
        vitaminId: vitaminId,
        scheduledTime: today,
        takenTime: DateTime.now(),
        isTaken: true,
      );
      final intakeId = await dbService.insertVitaminIntake(intake);
      await dbService.updateVitaminIntakeWithCloudSync(
        intake.copyWith(id: intakeId),
      );
    } else if (!todayIntake.isTaken) {
      await dbService.updateVitaminIntakeWithCloudSync(
        todayIntake.copyWith(isTaken: true, takenTime: DateTime.now()),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'VitaTracker',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28, color: Color(0xFF409CFF)),
            tooltip: 'Настройки приложения',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Vitamin>>(
        future: _vitaminsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final vitamins = snapshot.data ?? [];

          if (vitamins.isEmpty) {
            return const Center(
              child: Text(
                'Добавьте витамины для отслеживания',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return FutureBuilder<Map<String, Map<String, int>>>(
            future: Provider.of<DatabaseService>(context, listen: false)
                .getPeriodTimes(),
            builder: (context, periodSnapshot) {
              if (!periodSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }


              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: vitamins.length,
                itemBuilder: (context, index) {
                  final vitamin = vitamins[index];
                  // Получаем все приёмы для витамина
                  final dbService = Provider.of<DatabaseService>(context, listen: false);
                  // Для асинхронного получения intakes используем FutureBuilder
                  return FutureBuilder<List<VitaminIntake>>(
                    future: dbService.getVitaminIntakes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                      }
                      final intakes = snapshot.data!.where((i) => i.vitaminId == vitamin.id).toList();
                      // Получаем общее количество дней курса
                      final totalDays = vitamin.endDate.difference(vitamin.startDate).inDays + 1;
                      // Считаем количество дней, когда был отмечен приём
                      final takenDays = intakes.where((i) => i.isTaken).length;
                      // Вычисляем оставшиеся дни
                      final daysLeft = totalDays - takenDays;
                      return VitaminCard(
                        vitamin: vitamin,
                        daysLeft: daysLeft,
                        intakes: intakes,
                        onShowCalendar: () => _showVitaminHistory(context, vitamin),
                        onInfo: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(vitamin.name),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (vitamin.description.isNotEmpty) ...[
                                      const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.description),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.benefits.isNotEmpty) ...[
                                      const Text('Польза:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.benefits),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.organs.isNotEmpty) ...[
                                      const Text('Органы:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.organs),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.dailyNorm.isNotEmpty) ...[
                                      const Text('Суточная норма:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.dailyNorm),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.bestTimeToTake?.isNotEmpty ?? false) ...[
                                      const Text('Лучшее время приёма:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.bestTimeToTake!),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.compatibleWith.isNotEmpty) ...[
                                      const Text('Совместим с:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.compatibleWith.join(', ')),
                                      const SizedBox(height: 16),
                                    ],
                                    if (vitamin.incompatibleWith.isNotEmpty) ...[
                                      const Text('Не совместим с:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(vitamin.incompatibleWith.join(', ')),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Закрыть'),
                                ),
                              ],
                            ),
                          );
                        },
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddVitaminScreen(vitamin: vitamin),
                            ),
                          );
                          if (result == true) {
                            _loadVitamins();
                            setState(() {});
                          }
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Удалить витамин?'),
                              content: Text('Вы уверены, что хотите удалить ${vitamin.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final dbService = Provider.of<DatabaseService>(context, listen: false);
                            final notificationService = Provider.of<NotificationService>(context, listen: false);
                            
                            // Удаляем все уведомления для этого витамина
                            final intakes = await dbService.getVitaminIntakesByVitaminId(vitamin.id!);
                            for (var intake in intakes) {
                              await notificationService.cancelNotification(intake.id!);
                            }
                            
                            // Удаляем витамин из базы данных и облака
                            await dbService.deleteVitaminWithCloudSync(vitamin.id!);
                            
                            if (!mounted) return;
                            _loadVitamins();
                            setState(() {});
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //     content: Text('Витамин "${vitamin.name}" удалён'),
                            //     backgroundColor: Colors.red,
                            //   ),
                            // );
                          }
                        },
                        onTake: () async {
                          await _markTodayIntakeAsTaken(vitamin.id!);
                          if (!mounted) return;
                          await Future.delayed(const Duration(milliseconds: 100));
                          _loadVitamins();
                          setState(() {});
                          if(mounted){
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Приём витамина "${vitamin.name}" отмечен!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVitaminScreen()),
          );
          if (result == true) {
            refresh();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showVitaminHistory(BuildContext context, Vitamin vitamin) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final intakes = await dbService.getVitaminIntakesByVitaminId(vitamin.id!);
    
    // Создаем множества дат для принятых и пропущенных приёмов
    final takenDates = intakes
        .where((i) => i.isTaken)
        .map((i) => DateTime(
              i.takenTime.year,
              i.takenTime.month,
              i.takenTime.day,
            ))
        .toSet();

    final missedDates = intakes
        .where((i) => !i.isTaken && i.scheduledTime.isBefore(DateTime.now()))
        .map((i) => DateTime(
              i.scheduledTime.year,
              i.scheduledTime.month,
              i.scheduledTime.day,
            ))
        .toSet();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(  
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                    vitamin.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
            ),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'ru_RU',
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  if (takenDates.contains(date)) return [1];
                  if (missedDates.contains(date)) return [2];
                  return [];
                },
                onDaySelected: (selectedDay, focusedDay) async {
                  final today = DateTime.now();
                  final selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  if (selectedDate.isAfter(DateTime(today.year, today.month, today.day))) return;
                  final dbService = Provider.of<DatabaseService>(context, listen: false);
                  final intakes = await dbService.getVitaminIntakesByVitaminId(vitamin.id!);
                  VitaminIntake? intakeForDay;
                  try {
                    intakeForDay = intakes.firstWhere(
                      (i) =>
                        i.scheduledTime.year == selectedDate.year &&
                        i.scheduledTime.month == selectedDate.month &&
                        i.scheduledTime.day == selectedDate.day,
                    );
                  } catch (_) {
                    intakeForDay = null;
                  }
                  if (intakeForDay != null) {
                    if (intakeForDay.isTaken) {
                      // Удалить intake полностью с cloud sync
                      if (intakeForDay.id != null) {
                        await dbService.deleteVitaminIntakeWithCloudSync(intakeForDay.id!);
                      }
                    } else {
                      // Отметить как принято (cloud sync)
                      await dbService.updateVitaminIntakeWithCloudSync(
                        intakeForDay.copyWith(isTaken: true, takenTime: selectedDate),
                      );
                    }
                  } else {
                    // Создать intake и отметить как принято (cloud sync)
                    final newId = await dbService.insertVitaminIntake(
                      VitaminIntake(
                        vitaminId: vitamin.id!,
                        scheduledTime: selectedDate,
                        takenTime: selectedDate,
                        isTaken: true,
                      ),
                    );
                    await dbService.updateVitaminIntakeWithCloudSync(
                      VitaminIntake(
                        id: newId,
                        vitaminId: vitamin.id!,
                        scheduledTime: selectedDate,
                        takenTime: selectedDate,
                        isTaken: true,
                      ),
                    );
                  }
                  // Обновить UI
                  final updatedIntakes = await dbService.getVitaminIntakesByVitaminId(vitamin.id!);
                  takenDates
                    ..clear()
                    ..addAll(updatedIntakes.where((i) => i.isTaken).map((i) => DateTime(i.takenTime.year, i.takenTime.month, i.takenTime.day)));
                  missedDates
                    ..clear()
                    ..addAll(updatedIntakes.where((i) => !i.isTaken && i.scheduledTime.isBefore(DateTime.now())).map((i) => DateTime(i.scheduledTime.year, i.scheduledTime.month, i.scheduledTime.day)));
                  (context as Element).markNeedsBuild();
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),

                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    final color = events.contains(1) ? Colors.green : Colors.red;
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Принято'),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Пропущено'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // После закрытия календаря обновляем витамины и UI
    _loadVitamins();
    setState(() {});
  }
}

class VitaminCard extends StatelessWidget {
  final Vitamin vitamin;
  final int daysLeft;
  final List<VitaminIntake> intakes;
  final VoidCallback onShowCalendar;
  final VoidCallback onInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTake;
  const VitaminCard({
    super.key,
    required this.vitamin,
    required this.daysLeft,
    required this.intakes,
    required this.onShowCalendar,
    required this.onInfo,
    required this.onEdit,
    required this.onDelete,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Цветная полоса с аббревиатурой
            Container(
              width: 60,
              decoration: BoxDecoration(
                color: Color(vitamin.color),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
              alignment: Alignment.center,
              child: Text(
                vitamin.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            // Основное содержимое карточки
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая часть карточки
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название витамина
                          Text(
                            vitamin.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Период приема и связь с едой
                          Text(
                            '${vitamin.period}, ${vitamin.mealRelation}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Иконки действий
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: onShowCalendar,
                                tooltip: 'История',
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                                onPressed: onInfo,
                                tooltip: 'Информация',
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                onPressed: onEdit,
                                tooltip: 'Редактировать',
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: onDelete,
                                tooltip: 'Удалить',
                                padding: const EdgeInsets.all(8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Правая часть карточки
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Счетчик дней
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$daysLeft дн.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Кнопка принять
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, size: 36),
                          color: Colors.green,
                          onPressed: onTake,
                          tooltip: 'Отметить приём за сегодня',
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
