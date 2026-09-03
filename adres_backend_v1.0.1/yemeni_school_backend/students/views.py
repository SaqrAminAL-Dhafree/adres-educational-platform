from rest_framework.generics import ListAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Student
from .serializers import StudentSerializer


class StudentListAPIView(ListAPIView):
    serializer_class = StudentSerializer

    def get_queryset(self):
        qs = Student.objects.all()
        academic_id = self.request.query_params.get('academic_id')
        if academic_id:
            qs = qs.filter(academic_id=academic_id)
        return qs

    def post(self, request):
        """POST /api/students/ - إنشاء طالب جديد"""
        serializer = StudentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class StudentUpdateClassAPIView(APIView):
    """PATCH /api/students/<academic_id>/update_class/  body: {class_id, class_name}"""

    def patch(self, request, academic_id):
        try:
            student = Student.objects.get(academic_id=academic_id)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        student.class_id = request.data.get('class_id', student.class_id)
        student.class_name = request.data.get('class_name', student.class_name)
        student.save()
        return Response(StudentSerializer(student).data)


class StudentDetailAPIView(APIView):
    """GET/PUT/DELETE /api/students/<academic_id>/"""

    def get(self, request, academic_id):
        try:
            student = Student.objects.get(academic_id=academic_id)
            return Response(StudentSerializer(student).data)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, academic_id):
        try:
            student = Student.objects.get(academic_id=academic_id)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)
        serializer = StudentSerializer(student, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, academic_id):
        try:
            student = Student.objects.get(academic_id=academic_id)
            student.delete()
            return Response({'success': True}, status=status.HTTP_200_OK)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)


class StudentSetPasswordAPIView(APIView):
    """POST /api/students/<academic_id>/set_password/  body: {password}"""

    def post(self, request, academic_id):
        try:
            student = Student.objects.get(academic_id=academic_id)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        password = request.data.get('password', '').strip()
        if not password:
            return Response({'error': 'كلمة المرور مطلوبة'}, status=status.HTTP_400_BAD_REQUEST)

        student.password = password
        student.save()
        return Response({'success': True})
