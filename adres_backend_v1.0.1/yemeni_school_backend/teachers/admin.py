from django.contrib import admin
from django.contrib.auth.hashers import make_password
from django import forms
from django.urls import path
from django.shortcuts import get_object_or_404, redirect
from django.contrib import messages
from .models import Teacher, TeacherClass, TeacherStudent
from students.models import Student


class TeacherClassInline(admin.TabularInline):
    model = TeacherClass
    extra = 1


class TeacherStudentInline(admin.TabularInline):
    """لتعديل شعبة الطلاب المُسندين فقط"""
    model = TeacherStudent
    extra = 0
    verbose_name = "تعديل شعبة طالب"
    verbose_name_plural = "تعديل شعب الطلاب المُسندين"
    fields = ['student', 'class_name']
    readonly_fields = ['student']

    def has_add_permission(self, request, obj=None):
        return False


class TeacherAdminForm(forms.ModelForm):
    new_password = forms.CharField(
        label='كلمة مرور جديدة',
        required=False,
        widget=forms.PasswordInput(render_value=False),
        help_text='اتركه فارغاً للإبقاء على كلمة المرور الحالية',
    )
    # حقل الإضافة بنفس أسلوب filter_horizontal
    students = forms.ModelMultipleChoiceField(
        queryset=Student.objects.all(),
        required=False,
        widget=admin.widgets.FilteredSelectMultiple('الطلاب', False),
        label='إضافة / حذف طلاب',
        help_text='اختر الطلاب من القائمة اليسرى وانقلهم لليمين للإسناد',
    )

    class Meta:
        model = Teacher
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['password'].widget = forms.HiddenInput()
        self.fields['password'].required = False
        # تحميل الطلاب الحاليين
        if self.instance.pk:
            self.fields['students'].initial = self.instance.students.all()

    def save(self, commit=True):
        teacher = super().save(commit=commit)
        if commit:
            selected = self.cleaned_data.get('students', [])
            current = set(teacher.students.all())
            selected_set = set(selected)
            # إضافة الجدد
            for s in selected_set - current:
                TeacherStudent.objects.get_or_create(teacher=teacher, student=s)
            # حذف المحذوفين
            TeacherStudent.objects.filter(
                teacher=teacher, student__in=current - selected_set
            ).delete()
        return teacher


@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    form = TeacherAdminForm
    list_display = ['teacher_id', 'full_name', 'subject', 'students_count']
    search_fields = ['teacher_id', 'full_name']
    inlines = [TeacherStudentInline, TeacherClassInline]

    class Media:
        css = {'all': ('admin/css/widgets.css',)}
        js = ('admin/js/core.js', 'admin/js/SelectBox.js', 'admin/js/SelectFilter2.js')

    def students_count(self, obj):
        return obj.students.count()
    students_count.short_description = 'عدد الطلاب'

    def save_model(self, request, obj, form, change):
        new_pw = form.cleaned_data.get('new_password', '').strip()
        if new_pw:
            obj.password = make_password(new_pw)
        elif not change:
            obj.password = make_password('123456')
        super().save_model(request, obj, form, change)
