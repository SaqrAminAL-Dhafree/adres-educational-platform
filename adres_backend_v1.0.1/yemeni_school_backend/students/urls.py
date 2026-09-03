from django.urls import path
from .views import StudentListAPIView, StudentUpdateClassAPIView, StudentDetailAPIView, StudentSetPasswordAPIView

urlpatterns = [
    path('students/', StudentListAPIView.as_view(), name='student-list'),
    path('students/<str:academic_id>/', StudentDetailAPIView.as_view(), name='student-detail'),
    path('students/<str:academic_id>/update_class/', StudentUpdateClassAPIView.as_view(), name='student-update-class'),
    path('students/<str:academic_id>/set_password/', StudentSetPasswordAPIView.as_view(), name='student-set-password'),
]
