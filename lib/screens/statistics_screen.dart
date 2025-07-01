import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/vitamin.dart';
import '../models/vitamin_intake.dart';
import '../components/my_app_bar.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _showTaken = false;
  bool _showMissed = false;
  bool _showAll = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Статистика',
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _getIntakeCounts(context),
        builder: (context, snapshot) {
          final counts =
              snapshot.data ?? {'taken': 0, 'missed': 0, 'compliance_rate': 0};
          return Column(
            children: [
              // Фильтры с количеством
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterCard(
                        'Принято',
                        Icons.check_circle,
                        Colors.green,
                        _showTaken,
                        () => setState(() {
                          _showTaken = !_showTaken;
                          _showMissed = false;
                          _showAll = !_showTaken;
                        }),
                        count: counts['taken'],
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterCard(
                        'Пропущено',
                        Icons.cancel,
                        Colors.red,
                        _showMissed,
                        () => setState(() {
                          _showMissed = !_showMissed;
                          _showTaken = false;
                          _showAll = !_showMissed;
                        }),
                        count: counts['missed'],
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterCard(
                        'Соблюдение',
                        Icons.percent,
                        Colors.blue,
                        false,
                        null,
                        count: counts['compliance_rate'],
                        enabled: false,
                        suffix: '%',
                      ),
                    ),
                  ],
                ),
              ),
              // Карточка пройденных курсов
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: _showCompletedCourses,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.2),
                          Colors.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events,
                                size: 32, color: Colors.amber),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Пройденные курсы',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Успешно завершённые курсы приёма витаминов',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FutureBuilder<int>(
                              future: Provider.of<DatabaseService>(context,
                                      listen: false)
                                  .getCompletedCoursesCount(),
                              builder: (context, snapshot) {
                                return Text(
                                  '${snapshot.data ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Заголовок истории
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'История приёма',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Список приёмов
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _showAll
                      ? Provider.of<DatabaseService>(context, listen: false)
                          .getAllIntakes()
                      : Provider.of<DatabaseService>(context, listen: false)
                          .getFilteredIntakes(_showTaken, _showMissed, false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: \\${snapshot.error}'));
                    }

                    final intakes = snapshot.data ?? [];

                    if (intakes.isEmpty) {
                      return const Center(
                        child: Text('Нет данных для отображения'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: intakes.length,
                      itemBuilder: (context, index) {
                        final intake = intakes[index];
                        final scheduledTime =
                            DateTime.parse(intake['scheduled_time']);
                        final isTaken = intake['is_taken'] == 1;
                        final isMissed =
                            !isTaken && scheduledTime.isBefore(DateTime.now());
                        final color = Color(intake['color'] as int);

                        // Показываем только принятые и пропущенные
                        if (!isTaken && !isMissed)
                          return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.1),
                                color.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [

                                // иконка витамина
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      intake['abbreviation'] as String,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // название витамина, время и статус
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // название витамина
                                      Text(
                                        intake['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // иконка времени
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDateTime(scheduledTime),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // иконка принято или пропущено
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isTaken
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isTaken
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: isTaken
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isTaken
                                                    ? 'Принято'
                                                    : 'Пропущено',
                                                style: TextStyle(
                                                  color: isTaken
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Получение количества приёмов
  Future<Map<String, int>> _getIntakeCounts(BuildContext context) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final all = await db.getAllIntakes();
    int taken = all.where((i) => i['is_taken'] == 1).length;
    int missed = all
        .where((i) =>
            i['is_taken'] == 0 &&
            DateTime.tryParse(i['scheduled_time'].toString())
                    ?.isBefore(DateTime.now()) ==
                true)
        .length;
    int total = taken + missed;
    double complianceRate = total > 0 ? (taken / total * 100) : 0;
    return {
      'taken': taken,
      'missed': missed,
      'compliance_rate': complianceRate.round(),
    };
  }

  Widget _buildFilterCard(
    String title,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback? onTap, {
    int? count,
    bool enabled = true,
    String? suffix,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    color.withOpacity(0.3),
                    color.withOpacity(0.15),
                  ]
                : [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color.withOpacity(0.9) : color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? color.withOpacity(0.9)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (count != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.3)
                          : color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$count${suffix ?? ''}',
                      style: TextStyle(
                        color: isSelected ? color.withOpacity(0.9) : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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

  void _showCompletedCourses() async {
    final completedCourses =
        await Provider.of<DatabaseService>(context, listen: false)
            .getCompletedCourses();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Пройденные курсы',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: completedCourses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет пройденных курсов',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: completedCourses.length,
                      itemBuilder: (context, index) {
                        final course = completedCourses[index];
                        final startDate = DateTime.parse(course['start_date']);
                        final endDate = DateTime.parse(course['end_date']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color:
                                Color(course['color'] as int).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(course['color'] as int)
                                  .withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Color(course['color'] as int)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          course['abbreviation'] as String,
                                          style: TextStyle(
                                            color:
                                                Color(course['color'] as int),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Длительность: ${_calculateDuration(startDate, endDate)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final difference = end.difference(start);
    final days = difference.inDays;
    if (days == 0) {
      return 'Менее дня';
    } else if (days == 1) {
      return '1 день';
    } else if (days < 5) {
      return '$days дня';
    } else {
      return '$days дней';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }
}
