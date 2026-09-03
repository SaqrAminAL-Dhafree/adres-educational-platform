from django.urls import path
from .views import (
    TeacherLoginAPIView, TeacherListAPIView, TeacherDetailAPIView,
    TeacherAddStudentAPIView, TeacherRemoveStudentAPIView,
    TeacherAddClassAPIView, TeacherRemoveClassAPIView,
)

urlpatterns = [
    path('teachers/login/', TeacherLoginAPIView.as_view(), name='teacher-login'),
    path('teachers/', TeacherListAPIView.as_view(), name='teacher-list'),
    path('teachers/<str:teacher_id>/detail/', TeacherDetailAPIView.as_view(), name='teacher-detail'),
    path('teachers/<str:teacher_id>/add_student/', TeacherAddStudentAPIView.as_view(), name='teacher-add-student'),
    path('teachers/<str:teacher_id>/remove_student/<str:academic_id>/', TeacherRemoveStudentAPIView.as_view(), name='teacher-remove-student'),
    path('teachers/<str:teacher_id>/add_class/', TeacherAddClassAPIView.as_view(), name='teacher-add-class'),
    path('teachers/<str:teacher_id>/remove_class/<str:class_id>/', TeacherRemoveClassAPIView.as_view(), name='teacher-remove-class'),
]
