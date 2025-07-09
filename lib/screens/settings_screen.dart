import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../components/my_app_bar.dart';
import '../services/auth_service.dart';
import '../components/gradient_button.dart';
import 'auth/login_screen.dart';
import '../components/notification_settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);


    return Scaffold(
      appBar: const MyAppBar(
        showBackButton : true,
        title: 'Настройки',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Секция пользователя
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
                        children: const[
                          Icon(Icons.person_outline, color: Color(0xFF1976D2)),
                           SizedBox(width: 8),
                          Text('Профиль', style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (authService.currentUser == null) ...[
                        GradientButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                          child: const Text('Войти', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      if (authService.currentUser != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: authService.currentUser?.photoURL != null
                                  ? NetworkImage(authService.currentUser!.photoURL!)
                                  : null,
                              child: authService.currentUser?.photoURL == null
                                  ? const Icon(Icons.person, size: 32)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authService.currentUser?.displayName ?? 'Пользователь',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authService.currentUser?.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          onPressed: () async {
                            try {
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка при выходе: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Выйти', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Секция темы
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
                          Icon(Icons.palette_outlined, color: Color(0xFF1976D2)),
                           SizedBox(width: 8),
                          Text('Тема', style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'light', label: Text('Светлая')),
                                ButtonSegment(value: 'dark', label: Text('Тёмная')),
                              ],
                              selected: {themeProvider.currentThemeName},
                              onSelectionChanged: (Set<String> newValue) {
                                if (newValue.isNotEmpty) {
                                  themeProvider.setTheme(newValue.first);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Секция уведомлений
              const NotificationSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
} 