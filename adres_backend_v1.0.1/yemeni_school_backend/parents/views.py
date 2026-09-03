from rest_framework.generics import ListAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Parent
from .serializers import ParentSerializer
from students.models import Student
from students.serializers import StudentSerializer


class ParentListAPIView(ListAPIView):
    """GET /api/parents/?parent_id=xxx"""
    serializer_class = ParentSerializer

    def get_queryset(self):
        qs = Parent.objects.all()
        parent_id = self.request.query_params.get('parent_id')
        if parent_id:
            qs = qs.filter(parent_id=parent_id)
        return qs

    def post(self, request):
        """POST /api/parents/ - إنشاء ولي أمر جديد"""
        parent_id = request.data.get('parent_id', '').strip()
        full_name = request.data.get('full_name', '').strip()
        if not parent_id or not full_name:
            return Response({'error': 'parent_id و full_name مطلوبان'}, status=status.HTTP_400_BAD_REQUEST)
        if Parent.objects.filter(parent_id=parent_id).exists():
            return Response({'error': 'رقم ولي الأمر مستخدم مسبقاً'}, status=status.HTTP_400_BAD_REQUEST)
        parent = Parent.objects.create(parent_id=parent_id, full_name=full_name)
        return Response(ParentSerializer(parent).data, status=status.HTTP_201_CREATED)


class ParentDetailAPIView(APIView):
    """GET/PUT/DELETE /api/parents/<parent_id>/detail/"""

    def get(self, request, parent_id):
        try:
            parent = Parent.objects.get(parent_id=parent_id)
            return Response(ParentSerializer(parent).data)
        except Parent.DoesNotExist:
            return Response({'error': 'ولي الأمر غير موجود'}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, parent_id):
        try:
            parent = Parent.objects.get(parent_id=parent_id)
        except Parent.DoesNotExist:
            return Response({'error': 'ولي الأمر غير موجود'}, status=status.HTTP_404_NOT_FOUND)
        parent.full_name = request.data.get('full_name', parent.full_name)
        parent.save()
        return Response(ParentSerializer(parent).data)

    def delete(self, request, parent_id):
        try:
            parent = Parent.objects.get(parent_id=parent_id)
            parent.delete()
            return Response({'success': True}, status=status.HTTP_200_OK)
        except Parent.DoesNotExist:
            return Response({'error': 'ولي الأمر غير موجود'}, status=status.HTTP_404_NOT_FOUND)


class ParentAddChildAPIView(APIView):
    """POST /api/parents/<parent_id>/add_child/  body: {academic_id: '...'}"""

    def post(self, request, parent_id):
        academic_id = request.data.get('academic_id', '').strip()
        if not academic_id:
            return Response({'error': 'academic_id مطلوب'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            parent = Parent.objects.get(parent_id=parent_id)
        except Parent.DoesNotExist:
            return Response({'error': 'ولي الأمر غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        try:
            student = Student.objects.get(academic_id=academic_id)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)

        parent.children.add(student)
        return Response(StudentSerializer(student).data, status=status.HTTP_200_OK)


class ParentRemoveChildAPIView(APIView):
    """DELETE /api/parents/<parent_id>/remove_child/<academic_id>/"""

    def delete(self, request, parent_id, academic_id):
        try:
            parent = Parent.objects.get(parent_id=parent_id)
            student = Student.objects.get(academic_id=academic_id)
            parent.children.remove(student)
            return Response({'success': True}, status=status.HTTP_200_OK)
        except Parent.DoesNotExist:
            return Response({'error': 'ولي الأمر غير موجود'}, status=status.HTTP_404_NOT_FOUND)
        except Student.DoesNotExist:
            return Response({'error': 'الطالب غير موجود'}, status=status.HTTP_404_NOT_FOUND)
