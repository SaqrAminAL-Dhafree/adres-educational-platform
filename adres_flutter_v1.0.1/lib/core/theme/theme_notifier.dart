import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _key = 'isDarkMode';
  static Box get _box => Hive.box('appBox');

  bool get isDark => _box.get(_key, defaultValue: false) as bool;

  void toggle() {
    _box.put(_key, !isDark);
    notifyListeners();
  }
}
