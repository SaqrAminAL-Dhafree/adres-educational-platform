import 'package:hive/hive.dart';

class TeacherLocalService {
  static Box get _box => Hive.box('teacherBox');

  static void saveTeacher(Map<String, dynamic> teacher) {
    _box.put('teacherData', teacher);
  }

  static Map<String, dynamic>? getTeacher() {
    final raw = _box.get('teacherData');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static bool hasTeacher() => _box.containsKey('teacherData');

  /// إضافة أو تحديث طالب في القائمة المحلية للمعلم
  static void addStudent(Map<String, dynamic> student) {
    final list = getStudents();
    final idx = list.indexWhere((s) => s['academic_id'] == student['academic_id']);
    if (idx >= 0) {
      list[idx] = student; // تحديث البيانات إذا كان موجوداً
    } else {
      list.add(student);
    }
    _box.put('teacherStudents', list);
  }

  static List<Map<String, dynamic>> getStudents() {
    final raw = _box.get('teacherStudents');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static void removeStudent(String academicId) {
    final list = getStudents()..removeWhere((s) => s['academic_id'] == academicId);
    _box.put('teacherStudents', list);
  }

  static void clearTeacher() {
    _box.deleteAll(['teacherData', 'teacherStudents']);
  }
}
