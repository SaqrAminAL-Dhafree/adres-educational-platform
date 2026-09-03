from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework import status
from .models import Teacher, TeacherStudent, TeacherClass
from .serializers import TeacherSerializer
from students.models import Student
from students.serializers import StudentSerializer


class TeacherLoginAPIView(APIView):
    """POST /api/teachers/login/"""

    def post(self, request):
        teacher_id = request.data.get('teacher_id', '').strip()
        password = request.data.get('password', '').strip()

        if not teacher_id or not password:
            return Response(
                {'error': 'الرجاء إدخال الرقم الوظيفي وكلمة المرور'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
            if not teacher.check_password(password):
                raise Teacher.DoesNotExist
            return Response(TeacherSerializer(teacher).data)
        except Teacher.DoesNotExist:
            return Response(
                {'error': 'بيانات الدخول غير صحيحة'},
                status=status.HTTP_401_UNAUTHORIZED,
            )


class TeacherListAPIView(ListAPIView):
    """GET /api/teachers/?teacher_id=xxx"""
    serializer_class = TeacherSerializer

    def get_queryset(self):
        qs = Teacher.objects.all()
        teacher_id = self.request.query_params.get('teacher_id')
        if teacher_id:
            qs = qs.filter(teacher_id=teacher_id)
        return qs

    def post(self, request):
        """POST /api/teachers/ - إنشاء معلم جديد"""
        teacher_id = request.data.get('teacher_id', '').strip()
        full_name = request.data.get('full_name', '').strip()
        subject = request.data.get('subject', '').strip()
        password = request.data.get('password', '').strip()

        if not teacher_id or not full_name or not password:
            return Response({'error': 'teacher_id و full_name و password مطلوبة'}, status=status.HTTP_400_BAD_REQUEST)

        if Teacher.objects.filter(teacher_id=teacher_id).exists():
            return Response({'error': 'الرقم الوظيفي مستخدم مسبقاً'}, status=status.HTTP_400_BAD_REQUEST)

        teacher = Teacher(teacher_id=teacher_id, full_name=full_name, subject=subject)
        teacher.set_password(password)
        teacher.save()
        return Response(TeacherSerializer(teacher).data, status=status.HTTP_201_CREATED)


class TeacherDetailAPIView(APIView):
    """GET/PUT/DELETE /api/teachers/<teacher_id>/detail/"""

    def get(self, request, teacher_id):
        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
            return Response(TeacherSerializer(teacher).data)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, teacher_id):
        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        teacher.full_name = request.data.get('full_name', teacher.full_name)
        teacher.subject = request.data.get('subject', teacher.subject)
        new_password = request.data.get('password', '').strip()
        if new_password:
            teacher.set_password(new_password)
        teacher.save()
        return Response(TeacherSerializer(teacher).data)

    def delete(self, request, teacher_id):
        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
            teacher.delete()
            return Response({'success': True}, status=status.HTTP_200_OK)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)


class TeacherAddStudentAPIView(APIView):
    """POST /api/teachers/<teacher_id>/add_student/
    body: {academic_id: '...', class_name: 'أ'}
    """

    def post(self, request, teacher_id):
        academic_id = request.data.get('academic_id', '').strip()
        class_name = request.data.get('class_name', '').strip()

        if not academic_id:
            return Response({'error': 'academic_id مطلوب'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        try:
            student = Student.objects.get(academic_id=academic_id)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        ts, _ = TeacherStudent.objects.update_or_create(
            teacher=teacher,
            student=student,
            defaults={'class_name': class_name},
        )
        data = StudentSerializer(student).data
        data['class_name'] = ts.class_name
        return Response(data, status=status.HTTP_200_OK)


class TeacherRemoveStudentAPIView(APIView):
    """DELETE /api/teachers/<teacher_id>/remove_student/<academic_id>/"""

    def delete(self, request, teacher_id, academic_id):
        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        deleted, _ = TeacherStudent.objects.filter(
            teacher=teacher, student__academic_id=academic_id
        ).delete()

        if deleted:
            return Response({'success': True}, status=status.HTTP_200_OK)
        return Response({'error': 'الطالب غير مُسند لهذا المعلم'}, status=status.HTTP_404_NOT_FOUND)


class TeacherAddClassAPIView(APIView):
    """POST /api/teachers/<teacher_id>/add_class/  body: {class_id, class_name, students_count}"""

    def post(self, request, teacher_id):
        try:
            teacher = Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return Response({'error': 'المعلم غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        class_id = request.data.get('class_id', '').strip()
        class_name = request.data.get('class_name', '').strip()
        students_count = request.data.get('students_count', 0)

        if not class_id or not class_name:
            return Response({'error': 'class_id و class_name مطلوبان'}, status=status.HTTP_400_BAD_REQUEST)

        tc, _ = TeacherClass.objects.update_or_create(
            teacher=teacher, class_id=class_id,
            defaults={'class_name': class_name, 'students_count': students_count}
        )
        return Response({'id': tc.id, 'class_id': tc.class_id, 'class_name': tc.class_name}, status=status.HTTP_200_OK)


class TeacherRemoveClassAPIView(APIView):
    """DELETE /api/teachers/<teacher_id>/remove_class/<class_id>/"""

    def delete(self, request, teacher_id, class_id):
        deleted, _ = TeacherClass.objects.filter(teacher__teacher_id=teacher_id, class_id=class_id).delete()
        if deleted:
            return Response({'success': True})
        return Response({'error': 'الشعبة غير موجودة'}, status=status.HTTP_404_NOT_FOUND)
