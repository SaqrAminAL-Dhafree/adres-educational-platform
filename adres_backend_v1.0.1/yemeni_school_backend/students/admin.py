from django.contrib import admin
from .models import Student


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['academic_id', 'full_name', 'grade_level', 'class_name', 'password']
    search_fields = ['academic_id', 'full_name']

    def get_readonly_fields(self, request, obj=None):
        # عند التعديل: الرقم الأكاديمي للقراءة فقط
        # عند الإنشاء: قابل للتعديل (مع قيمة افتراضية مولَّدة)
        if obj:
            return ['academic_id']
        return []
