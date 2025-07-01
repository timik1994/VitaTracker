import 'package:flutter/material.dart';
import 'package:vita_tracker/models/vitamin.dart';
import 'package:vita_tracker/models/vitamin_intake.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'package:table_calendar/table_calendar.dart';

class VitaminCard extends StatefulWidget {
  final Vitamin vitamin;
  final VoidCallback? onRefresh;

  const VitaminCard({
    Key? key, 
    required this.vitamin,
    this.onRefresh,
  }) : super(key: key);

  @override
  _VitaminCardState createState() => _VitaminCardState();
}

class _VitaminCardState extends State<VitaminCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(widget.vitamin.color);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final progressColor = isDark ? color.withOpacity(0.3) : color.withOpacity(0.2);
    
    // Вычисляем прогресс на основе дат
    final totalDays = widget.vitamin.endDate.difference(widget.vitamin.startDate).inDays + 1;
    final daysPassed = DateTime.now().difference(widget.vitamin.startDate).inDays;
    final progressValue = daysPassed / totalDays;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Верхняя часть с цветной полосой
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.vitamin.name.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vitamin.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.vitamin.dosage} ${widget.vitamin.unit}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showInfo(context),
                        tooltip: 'Информация',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Период',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.vitamin.period,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Приём',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.vitamin.mealRelation,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressValue.clamp(0.0, 1.0),
                      backgroundColor: progressColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showHistory(context),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('История'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _markAsTaken(context),
                          icon: const Icon(Icons.check),
                          label: const Text('Принять'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.vitamin.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.vitamin.description.isNotEmpty) ...[
                const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.description),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.benefits.isNotEmpty) ...[
                const Text('Польза:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.benefits),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.organs.isNotEmpty) ...[
                const Text('Органы:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.organs),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.dailyNorm.isNotEmpty) ...[
                const Text('Суточная норма:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.dailyNorm),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.bestTimeToTake?.isNotEmpty ?? false) ...[
                const Text('Лучшее время приёма:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.bestTimeToTake!),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.compatibleWith.isNotEmpty) ...[
                const Text('Совместим с:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.compatibleWith.join(', ')),
                const SizedBox(height: 16),
              ],
              if (widget.vitamin.incompatibleWith.isNotEmpty) ...[
                const Text('Не совместим с:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.vitamin.incompatibleWith.join(', ')),
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
  }

  void _showHistory(BuildContext context) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final intakes = await dbService.getVitaminIntakesByVitaminId(widget.vitamin.id!);
    
    // Создаем множество дат, когда витамин был принят
    final takenDates = intakes
        .where((i) => i.isTaken)
        .map((i) => DateTime(
              i.takenTime.year,
              i.takenTime.month,
              i.takenTime.day,
            ))
        .toSet();

    if (!mounted) return;

    showModalBottomSheet(
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'История приёма ${widget.vitamin.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                eventLoader: (day) {
                  return takenDates.contains(DateTime(day.year, day.month, day.day)) ? [1] : [];
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 0,
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(widget.vitamin.color),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(widget.vitamin.color).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статистика',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        'Всего принято',
                        takenDates.length.toString(),
                        Icons.check_circle_outline,
                      ),
                      _buildStatItem(
                        context,
                        'Пропущено',
                        (intakes.length - takenDates.length).toString(),
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _markAsTaken(BuildContext context) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Проверяем, есть ли уже приём за сегодня
      final intakes = await dbService.getVitaminIntakes();
      final todayIntake = intakes.firstWhere(
        (i) => 
          i.vitaminId == widget.vitamin.id &&
          i.scheduledTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          i.scheduledTime.isBefore(todayEnd),
        orElse: () => null as VitaminIntake,
      );

      if (todayIntake != null && todayIntake.isTaken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Витамин уже принят сегодня'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (todayIntake != null) {
        // Обновляем существующий приём
        await dbService.updateVitaminIntakeAsTaken(todayIntake.id!);
      } else {
        // Создаём новый приём
        final intakeId = await dbService.insertVitaminIntake(
          VitaminIntake(
            vitaminId: widget.vitamin.id!,
            scheduledTime: today,
            takenTime: today,
            isTaken: true,
          ),
        );
        await dbService.updateVitaminIntakeAsTaken(intakeId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Приём витамина "${widget.vitamin.name}" отмечен!'),
          backgroundColor: Colors.green,
        ),
      );

      // Обновляем список витаминов
      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 