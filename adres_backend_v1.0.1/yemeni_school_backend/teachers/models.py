from django.contrib.auth.hashers import make_password, check_password
from django.db import models
from students.models import Student


class Teacher(models.Model):
    teacher_id = models.CharField(max_length=20, unique=True, verbose_name="الرقم الوظيفي")
    password = models.CharField(max_length=128, verbose_name="كلمة المرور")
    full_name = models.CharField(max_length=100, verbose_name="الاسم الكامل")
    subject = models.CharField(max_length=100, verbose_name="المادة")
    students = models.ManyToManyField(
        Student,
        through='TeacherStudent',
        blank=True,
        related_name='teachers',
        verbose_name="الطلاب المُسندون",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.full_name} ({self.teacher_id})"

    class Meta:
        verbose_name = "معلم"
        verbose_name_plural = "المعلمون"


class TeacherStudent(models.Model):
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, verbose_name="المعلم")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, verbose_name="الطالب")
    class_name = models.CharField(max_length=100, blank=True, verbose_name="الشعبة")

    class Meta:
        unique_together = ('teacher', 'student')
        verbose_name = "طالب المعلم"
        verbose_name_plural = "طلاب المعلم"

    def __str__(self):
        return f"{self.student.full_name} ← {self.teacher.full_name} ({self.class_name})"


class TeacherClass(models.Model):
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name='classes')
    class_id = models.CharField(max_length=50, verbose_name="معرف الشعبة")
    class_name = models.CharField(max_length=100, verbose_name="اسم الشعبة")
    students_count = models.PositiveIntegerField(default=0, verbose_name="عدد الطلاب")

    def __str__(self):
        return f"{self.teacher.full_name} - {self.class_name}"

    class Meta:
        verbose_name = "شعبة المعلم"
        verbose_name_plural = "شعب المعلمين"
        unique_together = ('teacher', 'class_id')
