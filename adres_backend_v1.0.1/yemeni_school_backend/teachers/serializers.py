from rest_framework import serializers
from .models import Teacher, TeacherClass, TeacherStudent
from students.models import Student


class StudentProgressSerializer(serializers.ModelSerializer):
    avg_progress = serializers.SerializerMethodField()
    total_time_minutes = serializers.SerializerMethodField()
    class_name = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = ['id', 'academic_id', 'full_name', 'grade_level', 'class_name', 'avg_progress', 'total_time_minutes']

    def get_class_name(self, obj):
        # نجلب class_name من TeacherStudent إذا كان السياق يحتوي على المعلم
        teacher = self.context.get('teacher')
        if teacher:
            ts = TeacherStudent.objects.filter(teacher=teacher, student=obj).first()
            if ts and ts.class_name:
                return ts.class_name
        return obj.class_name

    def get_avg_progress(self, obj):
        from progress.models import Progress
        records = Progress.objects.filter(academic_id=obj.academic_id)
        if not records.exists():
            return 0.0
        return round(sum(r.progress_percent for r in records) / records.count(), 1)

    def get_total_time_minutes(self, obj):
        from progress.models import Progress
        from django.db.models import Sum
        result = Progress.objects.filter(academic_id=obj.academic_id).aggregate(Sum('total_time_minutes'))
        return result['total_time_minutes__sum'] or 0


class TeacherClassSerializer(serializers.ModelSerializer):
    active_rate = serializers.SerializerMethodField()

    class Meta:
        model = TeacherClass
        fields = ['id', 'class_id', 'class_name', 'students_count', 'active_rate']

    def get_active_rate(self, obj):
        try:
            from progress.models import Progress
            students = Student.objects.filter(class_id=obj.class_id)
            if not students.exists():
                return 0.0
            active = Progress.objects.filter(
                student__class_id=obj.class_id
            ).values('student').distinct().count()
            return round(active / students.count(), 2)
        except Exception:
            return 0.0


class TeacherSerializer(serializers.ModelSerializer):
    classes = TeacherClassSerializer(many=True, read_only=True)
    students = serializers.SerializerMethodField()

    class Meta:
        model = Teacher
        fields = ['id', 'teacher_id', 'full_name', 'subject', 'classes', 'students']

    def get_students(self, obj):
        return StudentProgressSerializer(
            obj.students.all(),
            many=True,
            context={'teacher': obj},
        ).data
