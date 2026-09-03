import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import 'teacher_student_report_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final String classId;
  final String className;
  final List<Map<String, dynamic>> assignedStudents;

  const TeacherClassScreen({
    super.key,
    required this.classId,
    required this.className,
    this.assignedStudents = const [],
  });

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  late List<Map<String, dynamic>> _students;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.assignedStudents);
    if (_students.isEmpty) _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final data = await ApiService.getClassStudents(widget.classId);
    if (mounted) {
      setState(() {
        _students = data;
        _loading = false;
      });
    }
  }

  Future<void> _openStudentReport(Map<String, dynamic> s) async {
    // جلب بيانات الطالب الكاملة من API باستخدام الرقم الأكاديمي
    final academicId = s['academic_id']?.toString() ?? '';
    Map<String, dynamic> studentData = Map.from(s);

    if (academicId.isNotEmpty) {
      final fetched = await ApiService.loginStudent(academicId);
      if (fetched != null) {
        studentData = {...studentData, ...fetched};
      }
      // جلب تقدم الطالب
      final progressList = await ApiService.getStudentAllProgress(academicId);
      if (progressList.isNotEmpty) {
        // حساب متوسط التقدم
        final avgProgress = progressList
                .map((p) => (p['progress_percent'] as num?)?.toDouble() ?? 0.0)
                .fold(0.0, (a, b) => a + b) /
            progressList.length;
        final totalMinutes = progressList
            .map((p) => (p['total_time_minutes'] as num?)?.toInt() ?? 0)
            .fold(0, (a, b) => a + b);
        studentData['progress_percent'] = avgProgress;
        studentData['total_time_minutes'] = totalMinutes;
        studentData['books_progress'] = progressList;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherStudentReportScreen(student: studentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('شعبة ${widget.className}'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب في هذه الشعبة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    final avg = (s['avg_progress'] as num?)?.toDouble() ?? 0.0;
                    final pct = avg.round();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.person,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(s['full_name'] ?? 'طالب'),
                        subtitle: Text(
                            '${s['grade_level'] ?? ''} • وقت القراءة: ${s['total_time_minutes'] ?? 0} دقيقة'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$pct٪',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pct >= 70
                                        ? Colors.green
                                        : pct >= 40
                                            ? Colors.orange
                                            : Colors.red)),
                            const Text('إنجاز', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        onTap: () => _openStudentReport(s),
                      ),
                    );
                  },
                ),
    );
  }
}
