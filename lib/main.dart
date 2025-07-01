import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/add_vitamin_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import '../theme/theme_provider.dart';
import 'dart:ui';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/auth/login_email_screen.dart';
import 'screens/auth/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final databaseService = DatabaseService();
  await databaseService.init();
  
  // Инициализация сервиса уведомлений с обработкой ошибок
  final notificationService = NotificationService();
  try {
    await notificationService.init();
    print('Сервис уведомлений успешно инициализирован');
  } catch (e) {
    print('Ошибка при инициализации сервиса уведомлений: $e');
  }
  
  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseService>(create: (_) => databaseService),
        ChangeNotifierProvider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaTracker',
      theme: Provider.of<ThemeProvider>(context).currentThemeData.copyWith(
        navigationBarTheme: const NavigationBarThemeData(
          height: 60,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return authService.currentUser == null
              ? const WelcomeScreen()
              : const MainScreen();
        },
      ),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/login_email': (context) => const LoginEmailScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return VerificationScreen(
            phoneNumber: args['phoneNumber'] as String,
            verificationId: args['verificationId'] as String,
          );
        },
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const AddVitaminScreen(),
    const StatisticsScreen(),
  ];

  Future<void> _onNavTap(int index) async {
    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddVitaminScreen()),
      );
      if (result == true) {
        setState(() {
          _currentIndex = 0;
        });
        Provider.of<DatabaseService>(context, listen: false).notifyListeners();
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.medical_services_outlined,
                  selectedIcon: Icons.medical_services,
                  label: 'Мои витамины',
                  index: 0,
                  colorScheme: colorScheme,
                  onTap: () => _onNavTap(0),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.add_circle_outline,
                  selectedIcon: Icons.add_circle,
                  label: 'Добавить',
                  index: 1,
                  colorScheme: colorScheme,
                  isCenter: true,
                  onTap: () => _onNavTap(1),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  label: 'Статистика',
                  index: 2,
                  colorScheme: colorScheme,
                  onTap: () => _onNavTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ColorScheme colorScheme,
    bool isCenter = false,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;
    final double iconSize = 26;
    final Color selectedColor = colorScheme.primary;
    final Color unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: iconSize,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
