import 'package:flutter/material.dart';

class TeacherStudentReportScreen extends StatelessWidget {
  final Map<String, dynamic> student;

  const TeacherStudentReportScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    // دعم كلا الحقلين: progress_percent (0-1) أو avg_progress (0-100)
    double progress = (student['progress_percent'] as num?)?.toDouble() ?? 0.0;
    if (progress > 1.0) progress = progress / 100.0; // تحويل من نسبة مئوية
    final pct = (progress * 100).round();
    final totalMinutes = (student['total_time_minutes'] as num?)?.toInt() ?? 0;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final booksProgress = student['books_progress'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير ${student['full_name'] ?? 'الطالب'}'),
        leading: const BackButton(),
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
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student['full_name'] ?? 'طالب',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('الرقم الأكاديمي: ${student['academic_id'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall),
                          if ((student['grade_level'] ?? '').toString().isNotEmpty)
                            Text('الصف: ${student['grade_level']}',
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ملخص التقدم
            Text('ملخص التقدم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نسبة الإنجاز'),
                        Text('$pct٪',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: progress >= 0.7
                                    ? Colors.green
                                    : progress >= 0.5
                                        ? Colors.orange
                                        : Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text('$pct٪ من محتوى المادة',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),

            // تقدم الكتب التفصيلي (إن وُجد)
            if (booksProgress.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('تقدم الكتب', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...booksProgress.map((bp) {
                final b = bp as Map;
                double bPct = (b['progress_percent'] as num?)?.toDouble() ?? 0.0;
                if (bPct > 1.0) bPct = bPct / 100.0;
                final bPctInt = (bPct * 100).round();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b['book_title']?.toString() ?? 'كتاب',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('$bPctInt٪',
                                style: TextStyle(
                                    color: bPct >= 0.7 ? Colors.green : Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: bPct,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // وقت الدراسة
            Text('وقت المذاكرة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                title: Text(
                  hours > 0
                      ? '$hours ساعة و$minutes دقيقة'
                      : '$minutes دقيقة',
                ),
                subtitle: const Text('إجمالي وقت الدراسة'),
              ),
            ),

            const SizedBox(height: 16),

            // آخر نشاط
            Text('آخر نشاط', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.orange),
                title: Text(student['last_activity'] as String? ?? 'غير محدد'),
                subtitle: const Text('آخر دخول'),
              ),
            ),

            const SizedBox(height: 16),

            // التقييم
            Text('التقييم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: progress >= 0.7
                  ? Colors.green.shade50
                  : progress >= 0.5
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  progress >= 0.7
                      ? 'الطالب يُظهر أداءً ممتازاً ومنتظماً في المذاكرة. يُنصح بالاستمرار.'
                      : progress >= 0.5
                          ? 'الطالب يحتاج إلى مزيد من الجهد. التقدم جيد لكن يمكن تحسينه.'
                          : 'الطالب يحتاج إلى متابعة ودعم. يرجى التواصل مع ولي الأمر.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
