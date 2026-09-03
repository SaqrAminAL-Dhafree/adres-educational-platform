import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/services/student_local_service.dart';
import '../../core/services/progress_local_service.dart';
import '../../core/services/reading_state_local_service.dart';
import '../../core/services/sync_local_service.dart';
import '../../core/services/api_service.dart';
import '../../core/account_type_screen.dart';
import '../../main.dart';
import 'grade_select_screen.dart';
import 'subject_screen.dart';
import 'book_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late Map<String, dynamic> _student;
  bool _syncing = false;

  // قائمة المواد مع معلوماتها
  final List<Map<String, dynamic>> _subjects = [
    {'id': '1', 'name': 'رياضيات', 'icon': Icons.calculate, 'color': Color(0xFF1E88E5)},
    {'id': '2', 'name': 'علوم', 'icon': Icons.science, 'color': Color(0xFF43A047)},
    {'id': '3', 'name': 'لغة عربية', 'icon': Icons.menu_book, 'color': Color(0xFFE53935)},
    {'id': '4', 'name': 'قرآن', 'icon': Icons.book, 'color': Color(0xFF6D4C41)},
    {'id': '5', 'name': 'إسلامية', 'icon': Icons.mosque, 'color': Color(0xFF00897B)},
    {'id': '6', 'name': 'تاريخ', 'icon': Icons.history_edu, 'color': Color(0xFFFFA000)},
  ];

  @override
  void initState() {
    super.initState();
    _student = StudentLocalService.getStudent();
    // محاولة المزامنة عند الدخول
    _trySync();
  }

  Future<void> _trySync() async {
    // إجبار إعادة المزامنة مرة واحدة بعد تحديث معادلة التقدم (v1.0.2)
    final box = Hive.box('studentBox');
    if (box.get('progress_formula_v102') != true) {
      SyncLocalService.markAllAsUnsynced();
      box.put('progress_formula_v102', true);
    }
    if (SyncLocalService.hasPendingSync()) {
      setState(() => _syncing = true);
      await SyncLocalService.syncProgressToServer();
      if (mounted) setState(() => _syncing = false);
    }
  }

  double _getOverallProgress() {
    double total = 0;
    int count = 0;
    for (final s in _subjects) {
      final progress = ProgressLocalService.getProgress(s['id'] as String);
      total += (progress['progressPercent'] as double? ?? 0.0);
      count++;
    }
    return count > 0 ? total / count : 0.0;
  }

  void _continueReading() {
    final lastReading = ReadingStateLocalService.getLastReading();
    if (lastReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم تبدأ القراءة بعد. اختر مادة للبداية.')),
      );
      return;
    }
    final bookId = lastReading['bookId'] as String? ?? '1';
    final lastPage = lastReading['lastPage'] as int? ?? 1;
    final subjectName = lastReading['subjectName'] as String? ?? 'رياضيات';
    final termName = lastReading['termName'] as String? ?? 'الفصل الأول';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookScreen(
          subjectName: subjectName,
          termName: termName,
          bookId: bookId,
          startPage: lastPage,
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              StudentLocalService.clearStudent();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AccountTypeScreen()),
                (route) => false,
              );
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool obscure = true;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تغيير كلمة المرور',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _passField(oldPass, 'كلمة المرور الحالية', obscure,
                  () => setS(() => obscure = !obscure)),
              const SizedBox(height: 10),
              _passField(newPass, 'كلمة المرور الجديدة', obscure,
                  () => setS(() => obscure = !obscure)),
              const SizedBox(height: 10),
              _passField(confirmPass, 'تأكيد كلمة المرور الجديدة', obscure,
                  () => setS(() => obscure = !obscure)),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final student = StudentLocalService.getStudent();
                    // التحقق من كلمة المرور الحالية عبر الـ API
                    final data = await ApiService.loginStudent(student['academicId']);
                    final currentPass = (data?['password'] ?? '').toString();
                    if (oldPass.text.trim() != currentPass) {
                      setS(() => error = 'كلمة المرور الحالية غير صحيحة');
                      return;
                    }
                    if (newPass.text.trim().isEmpty) {
                      setS(() => error = 'أدخل كلمة المرور الجديدة');
                      return;
                    }
                    if (newPass.text.trim() != confirmPass.text.trim()) {
                      setS(() => error = 'كلمتا المرور غير متطابقتين');
                      return;
                    }
                    final ok = await ApiService.setStudentPassword(
                        student['academicId'], newPass.text.trim());
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'تم تغيير كلمة المرور بنجاح ✅' : 'فشل التغيير، حاول مجدداً'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ));
                  },
                  child: const Text('حفظ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passField(TextEditingController c, String label, bool obscure, VoidCallback toggle) =>
      TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final progress = _getOverallProgress();
    final percent = (progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبًا ${_student['fullName']} 👋'),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'مزامنة',
            onPressed: _trySync,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.school, size: 30)),
                      const SizedBox(height: 8),
                      Text(_student['fullName'] ?? 'طالب',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(_student['academicId'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('تغيير كلمة المرور'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangePassword();
                },
              ),
              ListTile(
                leading: Icon(themeNotifier.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined),
                title: Text(themeNotifier.isDark
                    ? 'الوضع النهاري'
                    : 'الوضع الليلي'),
                onTap: () {
                  themeNotifier.toggle();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('الصفوف الدراسية'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const GradeSelectScreen()),
                  );
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الطالب
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.school,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_student['fullName'] ?? 'طالب',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${_student['gradeLevel']} • ${_student['className']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'الرقم الأكاديمي: ${_student['academicId']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // بطاقة التقدم
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقدمك العام',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percent٪ – ${percent >= 70 ? 'أداء ممتاز 🌟' : percent >= 50 ? 'أداء جيد 👍' : 'استمر في التقدم 💪'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_syncing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('جاري المزامنة مع السيرفر...',
                            style: TextStyle(fontSize: 12, color: Colors.blue)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // زر أكمل من حيث توقفت
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueReading,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('أكمل من حيث توقفت'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('المواد الدراسية',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),

            // شبكة المواد
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _subjects.map((subject) {
                final subProgress = ProgressLocalService.getProgress(subject['id'] as String);
                final pct = ((subProgress['progressPercent'] as double? ?? 0.0) * 100).round();
                return _SubjectCard(
                  title: subject['name'] as String,
                  icon: subject['icon'] as IconData,
                  color: subject['color'] as Color,
                  progress: subProgress['progressPercent'] as double? ?? 0.0,
                  percent: pct,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectScreen(
                          subjectName: subject['name'] as String,
                          subjectId: subject['id'] as String,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double progress;
  final int percent;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.progress,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(4),
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 4),
              Text('$percent٪',
                  style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
