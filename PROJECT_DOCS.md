# مشروع ادرس (ADRES) - التوثيق الشامل

---

## 1. نظرة عامة

**ادرس** منصة تعليمية يمنية تهدف إلى تسهيل متابعة الطلاب وتقدمهم الدراسي. يتكون المشروع من ثلاثة أجزاء رئيسية:

| الجزء | التقنية | الغرض |
|-------|---------|-------|
| Backend | Django REST Framework | السيرفر وقاعدة البيانات وواجهات API |
| تطبيق ادرس | Flutter | للطلاب والمعلمين وأولياء الأمور |
| تطبيق الإدارة | Flutter | لوحة تحكم إدارية كاملة |

---

## 2. هيكل المشروع

```
project1/
├── adres_backend_v1.0.1/          ← السيرفر (Django)
│   ├── .env                        ← مفاتيح البيئة (سري)
│   ├── requirements.txt
│   └── yemeni_school_backend/
│       ├── config/                 ← إعدادات Django + AI views
│       ├── students/               ← تطبيق الطلاب
│       ├── teachers/               ← تطبيق المعلمين
│       ├── parents/                ← تطبيق أولياء الأمور
│       ├── curriculum/             ← الكتب والمواد والصفحات
│       ├── progress/               ← تتبع تقدم الطلاب
│       └── summaries/              ← ملفات HTML للملخصات
│
├── adres_flutter_v1.0.1/          ← تطبيق الطلاب/المعلمين/أولياء الأمور
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── config/app_config.dart
│       │   ├── theme/app_theme.dart
│       │   ├── account_type_screen.dart
│       │   ├── server_settings_screen.dart
│       │   └── services/
│       │       ├── api_service.dart
│       │       ├── student_local_service.dart
│       │       ├── parent_local_service.dart
│       │       ├── teacher_local_service.dart
│       │       ├── progress_local_service.dart
│       │       ├── reading_state_local_service.dart
│       │       ├── sync_local_service.dart
│       │       └── ai_service.dart
│       └── features/
│           ├── splash/
│           ├── student/
│           ├── teacher/
│           └── parent/
│
└── adres_admin_flutter/           ← تطبيق الإدارة
    └── lib/
        ├── main.dart               ← Login + Home + Drawer + سجل العمليات
        ├── core/
        │   ├── api_service.dart    ← كل API calls للإدارة
        │   └── widgets.dart        ← مكونات مشتركة
        └── features/
            ├── students/
            ├── teachers/
            ├── parents/
            └── subjects/
```

---

## 3. الباك اند (Django REST Framework)

### تشغيل السيرفر
```bash
cd adres_backend_v1.0.1/yemeni_school_backend
python3 manage.py runserver 0.0.0.0:8000
```

### ملف `.env`
```env
DJANGO_SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=*
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxx
```

### التطبيقات (Apps)

| التطبيق | المسار | الوظيفة |
|---------|--------|---------|
| students | `/api/students/` | إدارة الطلاب |
| teachers | `/api/teachers/` | إدارة المعلمين |
| parents | `/api/parents/` | إدارة أولياء الأمور |
| curriculum | `/api/subjects/`, `/api/books/` | المواد والكتب والصفحات |
| progress | `/api/progress/` | تتبع تقدم الطلاب |
| config/ai_views | `/api/ai/explain/` | شرح النصوص بالذكاء الاصطناعي |

---

## 4. واجهات API الكاملة

### الطلاب
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| GET | `/api/students/` | جلب كل الطلاب |
| GET | `/api/students/?academic_id=X` | جلب طالب بالرقم الأكاديمي |
| POST | `/api/students/` | إنشاء طالب جديد |
| PUT | `/api/students/<academic_id>/` | تعديل بيانات طالب |
| DELETE | `/api/students/<academic_id>/` | حذف طالب |
| PATCH | `/api/students/<academic_id>/update_class/` | تحديث شعبة الطالب |

### المعلمون
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| GET | `/api/teachers/` | جلب كل المعلمين |
| POST | `/api/teachers/` | إنشاء معلم جديد |
| POST | `/api/teachers/login/` | تسجيل دخول المعلم |
| PUT | `/api/teachers/<teacher_id>/detail/` | تعديل بيانات معلم |
| DELETE | `/api/teachers/<teacher_id>/detail/` | حذف معلم |
| POST | `/api/teachers/<teacher_id>/add_student/` | إسناد طالب للمعلم |
| DELETE | `/api/teachers/<teacher_id>/remove_student/<academic_id>/` | إزالة طالب من المعلم |
| POST | `/api/teachers/<teacher_id>/add_class/` | إضافة شعبة للمعلم |
| DELETE | `/api/teachers/<teacher_id>/remove_class/<class_id>/` | حذف شعبة من المعلم |

### أولياء الأمور
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| GET | `/api/parents/` | جلب كل أولياء الأمور |
| POST | `/api/parents/` | إنشاء ولي أمر جديد |
| PUT | `/api/parents/<parent_id>/detail/` | تعديل بيانات ولي أمر |
| DELETE | `/api/parents/<parent_id>/detail/` | حذف ولي أمر |
| POST | `/api/parents/<parent_id>/add_child/` | إضافة ابن لولي الأمر |
| DELETE | `/api/parents/<parent_id>/remove_child/<academic_id>/` | حذف ابن من ولي الأمر |

### المنهج
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| GET | `/api/subjects/` | جلب المواد |
| POST | `/api/subjects/` | إضافة مادة |
| PUT | `/api/subjects/<id>/` | تعديل مادة |
| DELETE | `/api/subjects/<id>/` | حذف مادة |
| GET | `/api/books/` | جلب الكتب |
| GET | `/api/book-pages/<page_number>/` | صفحة كتاب بصيغة HTML |
| GET | `/api/summary-html/?book=1&page=5&type=1&summary_page=1` | صفحة ملخص HTML |

### التقدم
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| POST | `/api/progress/` | رفع تقدم طالب |
| GET | `/api/progress/?academic_id=X&book=1` | تقدم طالب في كتاب |
| GET | `/api/progress/student/<academic_id>/` | كل تقدم طالب |

### الذكاء الاصطناعي
| الطريقة | الرابط | الوصف |
|---------|--------|-------|
| POST | `/api/ai/explain/` | شرح نص بالذكاء الاصطناعي (Groq - llama-3.3-70b) |

---

## 5. قاعدة البيانات (SQLite - Django)

### جدول الطلاب `students_student`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| id | INTEGER PK | معرف تلقائي |
| academic_id | VARCHAR(20) UNIQUE | الرقم الأكاديمي |
| full_name | VARCHAR(100) | الاسم الكامل |
| grade_level | VARCHAR(50) | الصف الدراسي |
| class_id | VARCHAR(50) | معرف الشعبة |
| class_name | VARCHAR(100) | اسم الشعبة |
| created_at | DATETIME | تاريخ الإنشاء |

### جدول المعلمين `teachers_teacher`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| id | INTEGER PK | معرف تلقائي |
| teacher_id | VARCHAR(20) UNIQUE | الرقم الوظيفي |
| password | VARCHAR(128) | كلمة المرور (PBKDF2) |
| full_name | VARCHAR(100) | الاسم الكامل |
| subject | VARCHAR(100) | المادة |
| created_at | DATETIME | تاريخ الإنشاء |

### جدول طلاب المعلم `teachers_teacherstudent`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| teacher_id | FK → Teacher | المعلم |
| student_id | FK → Student | الطالب |
| class_name | VARCHAR(100) | الشعبة |
> قيد: `UNIQUE(teacher_id, student_id)`

### جدول شعب المعلم `teachers_teacherclass`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| teacher_id | FK → Teacher | المعلم |
| class_id | VARCHAR(50) | معرف الشعبة |
| class_name | VARCHAR(100) | اسم الشعبة |
| students_count | INTEGER | عدد الطلاب |

### جدول أولياء الأمور `parents_parent`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| parent_id | VARCHAR(20) UNIQUE | رقم ولي الأمر |
| full_name | VARCHAR(100) | الاسم الكامل |
| created_at | DATETIME | تاريخ الإنشاء |

### جدول الأبناء `parents_parent_children`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| parent_id | FK → Parent | ولي الأمر |
| student_id | FK → Student | الطالب |

### جدول المواد `curriculum_subject`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| name | VARCHAR(100) | اسم المادة |
| grade_level | VARCHAR(50) | الصف |
| education_stage | VARCHAR(20) | primary / middle / secondary |
| order | INTEGER | ترتيب العرض |

### جدول الكتب `curriculum_book`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| title | VARCHAR(255) | عنوان الكتاب |
| term | VARCHAR(20) | first / second |
| total_pages | INTEGER | عدد الصفحات |
| subject_id | FK → Subject | المادة |

### جدول صفحات الكتاب `curriculum_bookpage`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| page_number | INTEGER | رقم الصفحة |
| content_html | TEXT | محتوى HTML |
| book_id | FK → Book | الكتاب |

### جدول الملخصات `curriculum_pagesummary`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| summary_type | INTEGER | 1=المثالي، 2=الوليجي، 3=ملخص3 |
| book_page_id | FK → BookPage | الصفحة |

### جدول التقدم `progress_progress`
| الحقل | النوع | الوصف |
|-------|-------|-------|
| academic_id | VARCHAR(20) | الرقم الأكاديمي |
| book_id | FK → Book | الكتاب |
| last_page | INTEGER | آخر صفحة |
| pages_read | INTEGER | صفحات مقروءة |
| total_time_minutes | INTEGER | وقت القراءة (دقيقة) |
| interaction_score | INTEGER | نقاط التفاعل |
| progress_percent | REAL | نسبة الإنجاز (0.0 - 1.0) |
| updated_at | DATETIME | آخر تحديث |
> قيد: `UNIQUE(academic_id, book)`

---

## 6. تطبيق ادرس (adres_flutter_v1.0.1)

### المستخدمون
| النوع | طريقة الدخول | الشاشات |
|-------|-------------|---------|
| طالب | الرقم الأكاديمي | الرئيسية → المواد → الكتاب (قراءة تفاعلية) |
| معلم | الرقم الوظيفي + كلمة مرور | لوحة التحكم → الشعبة → تقرير الطالب |
| ولي أمر | رقم ولي الأمر | الرئيسية → لوحة الابن |

### المكتبات المستخدمة
| المكتبة | الإصدار | الاستخدام |
|---------|---------|-----------|
| http | ^1.1.0 | الاتصال بالـ API |
| hive | ^2.2.3 | التخزين المحلي |
| hive_flutter | ^1.1.0 | تهيئة Hive مع Flutter |
| webview_flutter | ^4.4.4 | عرض صفحات الكتاب HTML |
| connectivity_plus | ^5.0.2 | فحص الاتصال بالإنترنت |

### التخزين المحلي (Hive Boxes)
| الـ Box | المحتوى |
|---------|---------|
| `studentBox` | بيانات الطالب + ولي الأمر + التقدم |
| `teacherBox` | بيانات المعلم وطلابه |
| `appBox` | رابط السيرفر + كاش الصفحات |

### معادلة حساب التقدم
```
timeScore  = min(totalTimeSeconds / (totalPages × 10), 1.0)  → وزن 40%
pagesScore = uniquePagesOpened / totalPages                   → وزن 40%
clickScore = min(totalClicks / (totalPages × 5), 1.0)        → وزن 20%
progressPercent = timeScore×0.4 + pagesScore×0.4 + clickScore×0.2
```

### الذكاء الاصطناعي
- **المزود**: Groq API
- **النموذج**: `llama-3.3-70b-versatile`
- **الاستخدام**: شرح النصوص المحددة أو الصفحة الكاملة
- **المهلة**: 35 ثانية | **الحد الأقصى**: 1024 token

---

## 7. تطبيق الإدارة (adres_admin_flutter)

### الميزات
- كلمة مرور لحماية التطبيق (محفوظة في SharedPreferences)
- تغيير كلمة المرور من الشريط الجانبي
- تسجيل الخروج
- سجل العمليات (إضافة / تعديل / حذف) مع الوقت ونوع العملية

### الصفحات
| الصفحة | الملف | الوظيفة |
|--------|-------|---------|
| تسجيل الدخول | `main.dart` | كلمة مرور للدخول |
| الرئيسية | `main.dart` | 4 أقسام + سجل العمليات + Drawer |
| الطلاب | `students_screen.dart` | إضافة / تعديل / حذف طلاب |
| المعلمون | `teachers_screen.dart` | إضافة / تعديل / حذف معلمين + إدارة طلابهم بشعبهم |
| أولياء الأمور | `parents_screen.dart` | إضافة / تعديل / حذف + إدارة الأبناء |
| المواد | `subjects_screen.dart` | إضافة / تعديل / حذف مواد دراسية |

### المكتبات المستخدمة
| المكتبة | الإصدار | الاستخدام |
|---------|---------|-----------|
| http | ^1.1.0 | الاتصال بالـ API |
| shared_preferences | ^2.2.2 | حفظ كلمة المرور محلياً |

### ميزة الشعب عند إضافة طالب للمعلم
عند إضافة طالب لمعلم، تظهر قائمة منسدلة تحتوي **شعب المعلم فقط** (المسجلة في `teachers_teacherclass`) بدلاً من حقل نصي حر.

---

## 8. العلاقات بين الجداول

```
students_student ←──── parents_parent_children  ────→ parents_parent
students_student ←──── teachers_teacherstudent  ────→ teachers_teacher
teachers_teacher ←──── teachers_teacherclass
students_student ←──── progress_progress        ────→ curriculum_book
curriculum_book  ←──── curriculum_bookpage
curriculum_book  ←──── curriculum_subject
curriculum_bookpage ←─ curriculum_pagesummary
curriculum_pagesummary ←─ curriculum_pagesummarypage
```

---

## 9. المزامنة بين المحلي والسيرفر

| البيانات | الاتجاه | متى |
|---------|---------|-----|
| تقدم الطالب | محلي → سيرفر | عند إغلاق الكتاب |
| بيانات ولي الأمر وأبنائه | سيرفر → محلي | عند تسجيل الدخول |
| بيانات المعلم وطلابه | سيرفر → محلي | عند الدخول + زر تحديث |
| بيانات الطالب | سيرفر → محلي | عند تسجيل الدخول |
| صفحات الكتاب | سيرفر → محلي (كاش) | عند فتح الصفحة لأول مرة |

---

## 10. بيانات تجريبية

| النوع | الرقم | كلمة المرور |
|-------|-------|-------------|
| طالب | `78246` | — |
| معلم | `78246` | `123` |
| ولي أمر | `78246` | — |
| إدارة | — | `2004` (قابلة للتغيير) |

---

## 11. ملاحظات تقنية

- **قاعدة البيانات**: SQLite للتطوير (ملف `db.sqlite3`)
- **المصادقة**: بدون JWT — رقم + كلمة مرور مشفرة بـ PBKDF2
- **اتجاه النص**: RTL (عربي)
- **الخط**: Cairo
- **الشبكة**: الجهاز والسيرفر يجب أن يكونا على نفس الشبكة (WiFi)
- **الكاش**: الصفحات تُحفظ محلياً بعد أول فتح وتعمل بدون إنترنت
- **مفتاح Groq**: لا تنشره علناً — Groq تلغيه تلقائياً عند اكتشافه
- **Flutter**: الإصدار 3.27.2 (stable)
- **Python**: 3.10+
