import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// خدمة الاتصال بالـ Backend
class ApiService {
  static String get base => AppConfig.backendBaseUrl;

  // ========== مصادقة الطالب ==========
  static Future<Map<String, dynamic>?> loginStudent(String academicId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/students/?academic_id=$academicId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  // ========== تعيين / تغيير كلمة مرور الطالب ==========
  static Future<bool> setStudentPassword(String academicId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/students/$academicId/set_password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ========== مصادقة المعلم ==========
  static Future<Map<String, dynamic>?> loginTeacher(
      String teacherId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/teachers/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teacher_id': teacherId, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ========== مصادقة ولي الأمر ==========
  static Future<Map<String, dynamic>?> loginParent(String parentId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/parents/?parent_id=$parentId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  // ========== إضافة طالب لولي الأمر ==========
  static Future<Map<String, dynamic>?> addChildToParent(
      String parentId, String childAcademicId) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/parents/$parentId/add_child/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'academic_id': childAcademicId}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ========== إضافة طالب للمعلم ==========
  static Future<Map<String, dynamic>?> addStudentToTeacher(
      String teacherId, String academicId, String className) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/teachers/$teacherId/add_student/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'academic_id': academicId, 'class_name': className}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ========== حذف طالب من المعلم ==========
  static Future<bool> removeStudentFromTeacher(
      String teacherId, String academicId) async {
    try {
      final res = await http.delete(
        Uri.parse('$base/api/teachers/$teacherId/remove_student/$academicId/'),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ========== تحديث شعبة الطالب ==========
  static Future<Map<String, dynamic>?> updateStudentClass(
      String academicId, String classId, String className) async {
    try {
      final res = await http.patch(
        Uri.parse('$base/api/students/$academicId/update_class/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'class_id': classId, 'class_name': className}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ========== تقدم الطالب ==========
  static Future<Map<String, dynamic>?> getStudentProgress(
      String academicId, String bookId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/progress/?academic_id=$academicId&book=$bookId'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ========== جلب بيانات المعلم ==========
  static Future<Map<String, dynamic>?> getTeacherData(String teacherId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/teachers/?teacher_id=$teacherId'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data[0]);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  // ========== تقدم الطالب الكامل ==========
  static Future<List<Map<String, dynamic>>> getStudentAllProgress(
      String academicId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/progress/student/$academicId/'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ========== طلاب الشعبة ==========
  static Future<List<Map<String, dynamic>>> getClassStudents(
      String classId) async {
    try {
      final res = await http.get(
        Uri.parse('$base/api/classes/$classId/students/'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ========== رفع التقدم ==========
  static Future<bool> syncProgress({
    required String academicId,
    required String bookId,
    required int lastPage,
    required int pagesRead,
    required int totalTimeMinutes,
    required int interactionScore,
    required double progressPercent,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$base/api/progress/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'academic_id': academicId,
          'book': int.tryParse(bookId) ?? 1,
          'last_page': lastPage,
          'pages_read': pagesRead,
          'total_time_minutes': totalTimeMinutes,
          'interaction_score': interactionScore,
          'progress_percent': progressPercent,
        }),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
