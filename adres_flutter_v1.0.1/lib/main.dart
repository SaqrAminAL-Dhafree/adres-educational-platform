import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/splash/splash_screen.dart';

final themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('studentBox');
  await Hive.openBox('parentBox');
  await Hive.openBox('teacherBox');
  await Hive.openBox('appBox');
  // مسح كاش الصفحات والملخصات عند تغيير الإصدار
  const cacheVersion = 'v3';
  final appBox = Hive.box('appBox');
  if (appBox.get('cache_version') != cacheVersion) {
    final keysToDelete = appBox.keys
        .where((k) => k.toString().startsWith('page_') || k.toString().startsWith('summary_'))
        .toList();
    for (final k in keysToDelete) {
      await appBox.delete(k);
    }
    await appBox.put('cache_version', cacheVersion);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ادرس',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
