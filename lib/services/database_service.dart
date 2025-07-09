import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vitamin.dart';
import '../models/vitamin_intake.dart';
import '../models/vitamin_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vitamin_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vitamins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        abbreviation TEXT NOT NULL,
        color INTEGER NOT NULL,
        dosage REAL NOT NULL,
        unit TEXT NOT NULL,
        period TEXT NOT NULL,
        meal_relation TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        compatible_with TEXT,
        incompatible_with TEXT,
        description TEXT,
        benefits TEXT,
        organs TEXT,
        daily_norm TEXT,
        best_time_to_take TEXT,
        form TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vitamin_intakes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vitamin_id INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        taken_time TEXT,
        is_taken INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (vitamin_id) REFERENCES vitamins (id) ON DELETE CASCADE
      )
    ''');
  }

  // Метод для ручного добавления базовых витаминов, если они нужны
  Future<void> insertInitialVitaminData() async {
    final db = await database;
    for (final vitamin in vitaminPresets) {
      await db.insert('vitamins', vitamin.toMap());
    }
  }

  // Методы для работы с витаминами
  Future<int> insertVitamin(Vitamin vitamin) async {
    final db = await database;
    return await db.insert('vitamins', vitamin.toMap());
  }

  Future<List<Vitamin>> getVitamins() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vitamins');
    return List.generate(maps.length, (i) => Vitamin.fromMap(maps[i]));
  }

  Future<int> updateVitamin(Vitamin vitamin) async {
    final db = await database;
    return await db.update(
      'vitamins',
      vitamin.toMap(),
      where: 'id = ?',
      whereArgs: [vitamin.id],
    );
  }

  Future<int> deleteVitamin(int id) async {
    final db = await database;
    // Удаляем все приёмы витамина
    await db.delete(
      'vitamin_intakes',
      where: 'vitamin_id = ?',
      whereArgs: [id],
    );
    // Удаляем сам витамин
    return await db.delete(
      'vitamins',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Методы для работы с приемами витаминов
  Future<int> insertVitaminIntake(VitaminIntake intake) async {
    final db = await database;
    return await db.insert('vitamin_intakes', intake.toMap());
  }

  Future<List<VitaminIntake>> getVitaminIntakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vitamin_intakes');
    return List.generate(maps.length, (i) => VitaminIntake.fromMap(maps[i]));
  }

  Future<List<VitaminIntake>> getVitaminIntakesByVitaminId(int vitaminId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vitamin_intakes',
      where: 'vitamin_id = ?',
      whereArgs: [vitaminId],
    );
    return List.generate(maps.length, (i) => VitaminIntake.fromMap(maps[i]));
  }

  Future<void> updateVitaminIntake(VitaminIntake intake) async {
    final db = await database;
    await db.update(
      'vitamin_intakes',
      intake.toMap(),
      where: 'id = ?',
      whereArgs: [intake.id],
    );
  }

  Future<List<VitaminIntake>> getPendingIntakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vitamin_intakes',
      where: 'is_taken = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => VitaminIntake.fromMap(maps[i]));
  }

  Future<int> updateVitaminIntakeAsTaken(int intakeId) async {
    final db = await database;
    return await db.update(
      'vitamin_intakes',
      {
        'is_taken': 1,
        'taken_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [intakeId],
    );
  }

  Future<void> updateVitaminIntakeAsMissed(int intakeId) async {
    final db = await database;
    await db.update(
      'vitamin_intakes',
      {
        'is_taken': 0,
        'taken_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [intakeId],
    );
  }

  // Сохранение промежутков времени для периодов
  Future<void> savePeriodTimes(Map<String, Map<String, int>> periods) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in periods.entries) {
      prefs.setInt('${entry.key}_start', entry.value['start']!);
      prefs.setInt('${entry.key}_end', entry.value['end']!);
    }
  }

  // Получение промежутков времени для периодов
  Future<Map<String, Map<String, int>>> getPeriodTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final periods = <String, Map<String, int>>{};
    for (final period in ['утро', 'день', 'вечер', 'перед сном']) {
      periods[period] = {
        'start': prefs.getInt('${period}_start') ?? (period == 'утро' ? 7 * 60 : period == 'день' ? 12 * 60 : period == 'вечер' ? 18 * 60 : 22 * 60),
        'end': prefs.getInt('${period}_end') ?? (period == 'утро' ? 9 * 60 : period == 'день' ? 15 * 60 : period == 'вечер' ? 20 * 60 : 23 * 60 + 59),
      };
    }
    return periods;
  }

  Future<Map<String, dynamic>> getVitaminInfo(String vitaminName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vitamin_info',
      where: 'name = ?',
      whereArgs: [vitaminName],
    );
    return maps.first;
  }

  // Получить завершённые курсы витаминов
  Future<List<Map<String, dynamic>>> getCompletedCourses() async {
    final db = await database;
    // Получаем все витамины, у которых дата окончания в прошлом
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> vitamins = await db.query(
      'vitamins',
      where: 'end_date < ?',
      whereArgs: [now],
    );
    List<Map<String, dynamic>> completedCourses = [];
    for (final vitamin in vitamins) {
      // Получаем все приёмы для этого витамина
      final int vitaminId = vitamin['id'];
      final List<Map<String, dynamic>> intakes = await db.query(
        'vitamin_intakes',
        where: 'vitamin_id = ?',
        whereArgs: [vitaminId],
      );
      // Если все приёмы отмечены как приняты (is_taken = 1), считаем курс завершённым
      if (intakes.isNotEmpty && intakes.every((i) => i['is_taken'] == 1)) {
        completedCourses.add({
          'name': vitamin['name'],
          'abbreviation': vitamin['abbreviation'],
          'color': vitamin['color'],
          'start_date': vitamin['start_date'],
          'end_date': vitamin['end_date'],
        });
      }
    }
    return completedCourses;
  }

  Future<int> getCompletedCoursesCount() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    // Получаем все витамины с завершенным сроком
    final List<Map<String, dynamic>> vitamins = await db.query(
      'vitamins',
      where: 'end_date < ?',
      whereArgs: [now],
    );

    int completedCount = 0;
    
    // Для каждого витамина проверяем, все ли приёмы были приняты
    for (final vitamin in vitamins) {
      final int vitaminId = vitamin['id'];
      final List<Map<String, dynamic>> intakes = await db.query(
        'vitamin_intakes',
        where: 'vitamin_id = ?',
        whereArgs: [vitaminId],
      );
      
      // Если есть приёмы и все они отмечены как принятые
      if (intakes.isNotEmpty && intakes.every((i) => i['is_taken'] == 1)) {
        completedCount++;
      }
    }
    
    return completedCount;
  }

  Future<List<Map<String, dynamic>>> getFilteredIntakes(
    bool showTaken,
    bool showMissed,
    bool showUpcoming,
  ) async {
    final db = await database;
    final now = DateTime.now();
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (showTaken && !showMissed && !showUpcoming) {
      whereClause = 'WHERE i.is_taken = 1';
    } else if (!showTaken && showMissed && !showUpcoming) {
      whereClause = 'WHERE i.is_taken = 0 AND i.scheduled_time < ?';
      whereArgs = [now.toIso8601String()];
    } else if (!showTaken && !showMissed && showUpcoming) {
      whereClause = 'WHERE i.scheduled_time > ?';
      whereArgs = [now.toIso8601String()];
    } else if (showTaken && showMissed && !showUpcoming) {
      whereClause = 'WHERE i.scheduled_time < ?';
      whereArgs = [now.toIso8601String()];
    } else if (showTaken && !showMissed && showUpcoming) {
      whereClause = 'WHERE i.is_taken = 1 OR i.scheduled_time > ?';
      whereArgs = [now.toIso8601String()];
    } else if (!showTaken && showMissed && showUpcoming) {
      whereClause = 'WHERE i.is_taken = 0';
    }
    
    final result = await db.rawQuery('''
      SELECT 
        i.*,
        v.name,
        v.color,
        v.abbreviation,
        CASE 
          WHEN i.is_taken = 1 THEN 'Принято'
          WHEN i.scheduled_time > ? THEN 'Предстоит'
          ELSE 'Пропущено'
        END as status
      FROM vitamin_intakes i
      JOIN vitamins v ON i.vitamin_id = v.id
      $whereClause
      ORDER BY i.scheduled_time DESC
    ''', [...whereArgs, now.toIso8601String()]);
    
    return result;
  }

  // Получить все приёмы витаминов без фильтрации
  Future<List<Map<String, dynamic>>> getAllIntakes() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        i.*,
        v.name,
        v.color,
        v.abbreviation,
        CASE 
          WHEN i.is_taken = 1 THEN 'Принято'
          WHEN i.scheduled_time > ? THEN 'Предстоит'
          ELSE 'Пропущено'
        END as status
      FROM vitamin_intakes i
      JOIN vitamins v ON i.vitamin_id = v.id
      ORDER BY i.scheduled_time DESC
    ''', [DateTime.now().toIso8601String()]);
    return result;
  }

  // Firestore helpers
  CollectionReference<Map<String, dynamic>> get _userVitaminsCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('vitamins');
  }

  CollectionReference<Map<String, dynamic>> get _userIntakesCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('vitamin_intakes');
  }

  // Сохранить витамин в Firestore
  Future<void> saveVitaminToCloud(Vitamin vitamin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = _userVitaminsCollection.doc(vitamin.id?.toString() ?? UniqueKey().toString());
    await doc.set(vitamin.toMap());
  }

  // Загрузить все витамины из Firestore
  Future<List<Vitamin>> loadVitaminsFromCloud() async {
    final snapshot = await _userVitaminsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = int.tryParse(doc.id);
      return Vitamin.fromMap(data);
    }).toList();
  }

  // Удалить витамин из Firestore
  Future<void> deleteVitaminFromCloud(String id) async {
    await _userVitaminsCollection.doc(id).delete();
  }

  // Сохранить приём витамина в Firestore
  Future<void> saveIntakeToCloud(VitaminIntake intake) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // id всегда обязателен для синхронизации
    if (intake.id == null) throw Exception('Intake id is required for cloud sync');
    final doc = _userIntakesCollection.doc(intake.id.toString());
    await doc.set(intake.toMap(forCloud: true));
  }

  // Загрузить все приёмы витаминов из Firestore
  Future<List<VitaminIntake>> loadIntakesFromCloud() async {
    final snapshot = await _userIntakesCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // id всегда берём из doc.id
      data['id'] = int.tryParse(doc.id);
      return VitaminIntake.fromMap(data);
    }).where((i) => i.id != null).toList();
  }

  // Удалить приём витамина из Firestore
  Future<void> deleteIntakeFromCloud(String id) async {
    await _userIntakesCollection.doc(id).delete();
  }

  // Вставить intake с заданным id (для syncFromCloud)
  Future<void> insertVitaminIntakeWithId(VitaminIntake intake) async {
    final db = await database;
    await db.insert('vitamin_intakes', intake.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Синхронизация: загрузить из облака и сохранить локально
  Future<void> syncFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final vitamins = await loadVitaminsFromCloud();
    final intakes = await loadIntakesFromCloud();
    final db = await database;
    await db.delete('vitamins');
    await db.delete('vitamin_intakes');
    for (final v in vitamins) {
      await db.insert('vitamins', v.toMap());
    }
    for (final i in intakes) {
      await insertVitaminIntakeWithId(i);
    }
    notifyListeners();
  }

  // Синхронизация: сохранить локальные данные в облако
  Future<void> syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final vitamins = await getVitamins();
    final intakes = await getVitaminIntakes();
    for (final v in vitamins) {
      await saveVitaminToCloud(v);
    }
    for (final i in intakes) {
      await saveIntakeToCloud(i);
    }
  }

  Future<void> deleteVitaminWithCloudSync(int id) async {
    // Проверяем авторизацию
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Только локальное удаление
      await deleteVitamin(id);
      return;
    }
    // Удалить из локальной базы сразу
    await deleteVitamin(id);
    // Удалить все приёмы этого витамина из облака параллельно (в фоне)
    final intakes = await getVitaminIntakesByVitaminId(id);
    Future.wait(intakes.map((intake) => deleteIntakeFromCloud(intake.id.toString())));
    // Удалить витамин из облака (в фоне)
    deleteVitaminFromCloud(id.toString());
  }

  Future<void> updateVitaminIntakeWithCloudSync(VitaminIntake intake) async {
    final user = FirebaseAuth.instance.currentUser;
    await updateVitaminIntake(intake);
    if (user == null) return;
    await saveIntakeToCloud(intake);
  }

  Future<int> insertVitaminWithCloudSync(Vitamin vitamin) async {
    final id = await insertVitamin(vitamin);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveVitaminToCloud(vitamin);
    }
    return id;
  }

  Future<int> deleteVitaminIntake(int id) async {
    final db = await database;
    return await db.delete(
      'vitamin_intakes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVitaminIntakeWithCloudSync(int id) async {
    final user = FirebaseAuth.instance.currentUser;
    await deleteVitaminIntake(id);
    if (user != null) {
      await deleteIntakeFromCloud(id.toString());
    }
  }
} 