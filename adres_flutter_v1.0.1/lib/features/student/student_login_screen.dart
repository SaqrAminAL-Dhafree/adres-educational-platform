import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/services/api_service.dart';
import '../../core/services/student_local_service.dart';
import '../../core/services/progress_local_service.dart';
import 'student_home_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;
  String? _error;

  // مراحل: 'id' → 'set_password' أو 'enter_password'
  String _step = 'id';
  Map<String, dynamic>? _studentData;
  bool _obscure = true;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submitId() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'الرجاء إدخال الرقم الأكاديمي');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final student = await ApiService.loginStudent(id);

    if (!mounted) return;
    setState(() => _loading = false);

    if (student == null) {
      setState(() => _error = 'الرقم الأكاديمي غير موجود.\nيرجى مراجعة المدرسة للتسجيل.');
      return;
    }

    _studentData = student;
    final hasPassword = (student['password'] ?? '').toString().isNotEmpty;

    setState(() => _step = hasPassword ? 'enter_password' : 'set_password');
  }

  Future<void> _submitSetPassword() async {
    final pass = _newPassController.text.trim();
    final confirm = _confirmPassController.text.trim();
    if (pass.isEmpty) { setState(() => _error = 'أدخل كلمة المرور'); return; }
    if (pass != confirm) { setState(() => _error = 'كلمتا المرور غير متطابقتين'); return; }

    setState(() { _loading = true; _error = null; });
    final ok = await ApiService.setStudentPassword(_studentData!['academic_id'], pass);
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      await _saveAndNavigate();
    } else {
      setState(() => _error = 'فشل حفظ كلمة المرور، حاول مجدداً');
    }
  }

  Future<void> _submitPassword() async {
    final pass = _passController.text.trim();
    if (pass.isEmpty) { setState(() => _error = 'أدخل كلمة المرور'); return; }

    if (pass != (_studentData!['password'] ?? '').toString()) {
      setState(() => _error = 'كلمة المرور غير صحيحة');
      return;
    }
    await _saveAndNavigate();
  }

  Future<void> _saveAndNavigate() async {
    final s = _studentData!;
    final academicId = s['academic_id'] as String;

    StudentLocalService.saveStudent(
      studentId: s['id']?.toString() ?? academicId,
      academicId: academicId,
      fullName: s['full_name'] ?? 'طالب',
      gradeLevel: s['grade_level'] ?? '',
      classId: s['class_id'] ?? '',
      className: s['class_name'] ?? '',
    );

    // جلب التقدم من السيرفر وحفظه محلياً
    try {
      final progressList = await ApiService.getStudentAllProgress(academicId);
      for (final p in progressList) {
        final bookId = p['book']?.toString() ?? '1';
        final serverPercent = (p['progress_percent'] as num?)?.toDouble() ?? 0.0;
        final local = ProgressLocalService.getProgress(bookId);
        final localPercent = local['progressPercent'] as double? ?? 0.0;
        // استخدم السيرفر فقط إذا كان أعلى من المحلي
        if (serverPercent > localPercent) {
          local['progressPercent'] = serverPercent;
          local['lastPage'] = p['last_page'] ?? local['lastPage'];
          local['pagesReadCount'] = p['pages_read'] ?? local['pagesReadCount'];
          local['totalTimeMinutes'] = p['total_time_minutes'] ?? local['totalTimeMinutes'];
          local['totalTimeSeconds'] = ((p['total_time_minutes'] as int? ?? 0) * 60);
          local['isSynced'] = true;
          Hive.box('studentBox').put('progress_$bookId', local);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('دخول الطالب'),
        leading: BackButton(onPressed: () {
          if (_step != 'id') {
            setState(() { _step = 'id'; _error = null; });
          } else {
            Navigator.pop(context);
          }
        }),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top - kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  if (_step == 'id') ..._buildIdStep(),
                  if (_step == 'set_password') ..._buildSetPasswordStep(),
                  if (_step == 'enter_password') ..._buildEnterPasswordStep(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBox(message: _error!),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onSubmit(),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_step == 'id' ? 'متابعة'
                              : _step == 'set_password' ? 'حفظ كلمة المرور'
                              : 'دخول'),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? _onSubmit() {
    if (_step == 'id') return _submitId;
    if (_step == 'set_password') return _submitSetPassword;
    return _submitPassword;
  }

  List<Widget> _buildIdStep() => [
    Text('مرحبًا بك 👋', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 12),
    Text('أدخل رقمك الأكاديمي للمتابعة إلى حسابك الدراسي.',
        style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 40),
    TextField(
      controller: _idController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'الرقم الأكاديمي',
        hintText: 'مثال: 78246',
        prefixIcon: Icon(Icons.badge_outlined),
        border: OutlineInputBorder(),
      ),
      onSubmitted: (_) => _submitId(),
    ),
  ];

  List<Widget> _buildSetPasswordStep() => [
    Text('إنشاء كلمة مرور 🔐', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 12),
    Text('أول مرة تدخل حسابك، أنشئ كلمة مرور لحماية حسابك.',
        style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 40),
    TextField(
      controller: _newPassController,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: 'كلمة المرور الجديدة',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _confirmPassController,
      obscureText: _obscure,
      decoration: const InputDecoration(
        labelText: 'تأكيد كلمة المرور',
        prefixIcon: Icon(Icons.lock_outline),
        border: OutlineInputBorder(),
      ),
      onSubmitted: (_) => _submitSetPassword(),
    ),
  ];

  List<Widget> _buildEnterPasswordStep() => [
    Text('أهلاً ${_studentData?['full_name'] ?? ''} 👋',
        style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 12),
    Text('أدخل كلمة المرور للدخول إلى حسابك.',
        style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 40),
    TextField(
      controller: _passController,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onSubmitted: (_) => _submitPassword(),
    ),
  ];
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
