import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../components/my_app_bar.dart';
import '../components/my_dropdown.dart';
import '../services/auth_service.dart';
import '../components/gradient_button.dart';
import 'auth/login_screen.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);

    final themeNamesRu = {
      'light': 'Светлая',
      'dark': 'Тёмная',
    };

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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Профиль',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (authService.currentUser != null) ...[
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: authService.currentUser?.photoURL != null
                            ? NetworkImage(authService.currentUser!.photoURL!)
                            : null,
                        child: authService.currentUser?.photoURL == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authService.currentUser?.displayName ?? 'Пользователь',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authService.currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                        child: const Text('Выйти', style: TextStyle(color: Colors.white),),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        onPressed: () async {
                          try {
                            await Provider.of<DatabaseService>(context, listen: false).syncFromCloud();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Данные успешно синхронизированы с облаком!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка синхронизации: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Синхронизировать с облаком', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Секция темы
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Тема',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MyDropdown<String>(
                      value: themeProvider.currentThemeName,
                      items: themeProvider.availableThemes.keys.where((k) => k == 'light' || k == 'dark').toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          themeProvider.setTheme(newValue);
                        }
                      },
                      itemLabel: (theme) => Text(themeNamesRu[theme] ?? theme),
                      hint: 'Выберите тему',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 