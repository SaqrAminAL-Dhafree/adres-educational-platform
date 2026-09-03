import 'package:flutter/material.dart';
import 'student_home_screen.dart';

class GradeSelectScreen extends StatelessWidget {
  const GradeSelectScreen({super.key});

  static const _grades = [
    {'label': 'الصف الأول',        'available': false},
    {'label': 'الصف الثاني',       'available': false},
    {'label': 'الصف الثالث',       'available': false},
    {'label': 'الصف الرابع',       'available': false},
    {'label': 'الصف الخامس',       'available': false},
    {'label': 'الصف السادس',       'available': false},
    {'label': 'الصف السابع',       'available': false},
    {'label': 'الصف الثامن',       'available': false},
    {'label': 'الصف التاسع',       'available': true},
    {'label': 'أول ثانوي',         'available': false},
    {'label': 'ثاني ثانوي',        'available': false},
    {'label': 'ثالث ثانوي',        'available': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر صفك الدراسي')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final grade = _grades[i];
          final available = grade['available'] as bool;
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            leading: Icon(
              available ? Icons.school_rounded : Icons.lock_outline_rounded,
              color: available
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(
              grade['label'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: available ? null : Colors.grey,
              ),
            ),
            subtitle: available
                ? null
                : const Text('سنضيفه قريباً', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: available
                ? Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: available
                ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
                  )
                : null,
          );
        },
      ),
    );
  }
}
