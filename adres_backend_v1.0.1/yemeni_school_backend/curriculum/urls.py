from django.urls import path
from .views import SubjectListAPIView, SubjectDetailAPIView, BookListAPIView
from .views import BookPageAPIView
from .views import PageSummaryListAPIView
from .views import PageSummaryPageAPIView
from .views import book_page_html_view
from .views import summary_page_html_view

urlpatterns = [
    path('subjects/', SubjectListAPIView.as_view(), name='subject-list'),
    path('subjects/<int:pk>/', SubjectDetailAPIView.as_view(), name='subject-detail'),
    path('books/', BookListAPIView.as_view(), name='book-list'),
    path('book-pages/', BookPageAPIView.as_view()),
    path('page-summaries/', PageSummaryListAPIView.as_view()),
    path('summary-pages/', PageSummaryPageAPIView.as_view()),
    path('book-pages/<int:page_number>/', book_page_html_view),
    path('summary-html/', summary_page_html_view),
]
