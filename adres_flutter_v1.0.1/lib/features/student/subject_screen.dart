import 'package:flutter/material.dart';
import 'book_screen.dart';

class SubjectScreen extends StatelessWidget {
  final String subjectName;
  final String subjectId;

  const SubjectScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
  });

  // المواد التي يوجد لها كتاب حالياً
  static const _availableSubjects = {'1'}; // رياضيات فقط

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = _availableSubjects.contains(subjectId);

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('الفصول الدراسية',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (!isAvailable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'سيتم إضافة هذه المادة قريباً',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _TermCard(
              termName: 'الفصل الدراسي الأول',
              subjectName: subjectName,
              bookId: subjectId,
              icon: Icons.book_outlined,
            ),
            const SizedBox(height: 12),
            _TermCard(
              termName: 'الفصل الدراسي الثاني',
              subjectName: subjectName,
              bookId: '${subjectId}_2',
              icon: Icons.book,
            ),
          ],
        ],
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  final String termName;
  final String subjectName;
  final String bookId;
  final IconData icon;

  const _TermCard({
    required this.termName,
    required this.subjectName,
    required this.bookId,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(termName),
        subtitle: Text('$subjectName - $termName'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookScreen(
                subjectName: subjectName,
                termName: termName,
                bookId: bookId,
                startPage: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
