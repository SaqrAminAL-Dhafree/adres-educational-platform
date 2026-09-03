from django.urls import path
from .views import ParentListAPIView, ParentDetailAPIView, ParentAddChildAPIView, ParentRemoveChildAPIView

urlpatterns = [
    path('parents/', ParentListAPIView.as_view(), name='parent-list'),
    path('parents/<str:parent_id>/detail/', ParentDetailAPIView.as_view(), name='parent-detail'),
    path('parents/<str:parent_id>/add_child/', ParentAddChildAPIView.as_view(), name='parent-add-child'),
    path('parents/<str:parent_id>/remove_child/<str:academic_id>/', ParentRemoveChildAPIView.as_view(), name='parent-remove-child'),
]
