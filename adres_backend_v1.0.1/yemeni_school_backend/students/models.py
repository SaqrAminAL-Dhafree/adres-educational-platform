from django.db import models
import re


def generate_academic_id():
    from students.models import Student
    ids = Student.objects.exclude(academic_id='').values_list('academic_id', flat=True)
    numeric = [int(i) for i in ids if re.fullmatch(r'\d+', i)]
    return str(max(numeric) + 1) if numeric else '78246'


class Student(models.Model):
    academic_id = models.CharField(max_length=20, unique=True, verbose_name="الرقم الأكاديمي", default=generate_academic_id)
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    grade_level = models.CharField(max_length=50, verbose_name="الصف الدراسي")
    class_id = models.CharField(max_length=50, blank=True, verbose_name="معرف الشعبة")
    class_name = models.CharField(max_length=100, blank=True, verbose_name="اسم الشعبة")
    password = models.CharField(max_length=128, blank=True, null=True, verbose_name="كلمة المرور")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} ({self.academic_id})"

    class Meta:
        verbose_name = "طالب"
        verbose_name_plural = "الطلاب"
