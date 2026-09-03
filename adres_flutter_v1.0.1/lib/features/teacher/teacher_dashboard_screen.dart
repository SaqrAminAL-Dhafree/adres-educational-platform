import 'package:flutter/material.dart';
import '../../core/account_type_screen.dart';
import '../../core/services/api_service.dart';
import 'teacher_class_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  const TeacherDashboardScreen({super.key, required this.teacher});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late Map<String, dynamic> _teacher;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final updated = await ApiService.getTeacherData(
        _teacher['teacher_id']?.toString() ?? '');
    if (mounted) {
      setState(() {
        if (updated != null) _teacher = updated;
        _refreshing = false;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AccountTypeScreen()),
              (route) => false,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = _teacher['classes'] as List? ?? [];
    final allStudents = (_teacher['students'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأستاذ'),
        automaticallyImplyLeading: false,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث البيانات',
              onPressed: _refresh,
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الأستاذ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: const Icon(Icons.school, size: 30, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_teacher['full_name'] ?? 'أستاذ',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('معلم ${_teacher['subject'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text('الرقم الوظيفي: ${_teacher['teacher_id'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('الصفوف الدراسية', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),

            if (classes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد صفوف مسجلة'),
                ),
              )
            else
              ...classes.map((cls) {
                final c = Map<String, dynamic>.from(cls as Map);
                final className = c['class_name']?.toString() ?? '';
                // طلاب هذه الشعبة من قائمة students المُسندين
                final classStudents = allStudents
                    .where((s) => s['class_name'] == className)
                    .toList();
                return _ClassCard(
                  classData: c,
                  studentsCount: classStudents.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherClassScreen(
                        classId: c['class_id']?.toString() ?? '',
                        className: className,
                        assignedStudents: classStudents,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final int studentsCount;
  final VoidCallback onTap;

  const _ClassCard({required this.classData, required this.studentsCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeRate = (classData['active_rate'] as num?)?.toDouble() ?? 0.0;
    final pct = (activeRate * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.class_, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(classData['class_name'] ?? 'الصف',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('$pct٪',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: activeRate >= 0.7 ? Colors.green : Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Text('عدد الطلاب: $studentsCount',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: activeRate,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
