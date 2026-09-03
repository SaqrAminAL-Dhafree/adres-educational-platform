from django.http import HttpResponse, Http404
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import NotFound

from .models import Subject, Book, BookPage, PageSummary, PageSummaryPage
from .serializers import (
    SubjectSerializer, BookSerializer, BookPageSerializer,
    PageSummarySerializer, PageSummaryPageSerializer,
)


class SubjectListAPIView(ListAPIView):
    queryset = Subject.objects.all().order_by('order')
    serializer_class = SubjectSerializer

    def post(self, request):
        """POST /api/subjects/ - إنشاء مادة جديدة"""
        serializer = SubjectSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SubjectDetailAPIView(APIView):
    """PUT/DELETE /api/subjects/<id>/"""

    def put(self, request, pk):
        try:
            subject = Subject.objects.get(pk=pk)
        except Subject.DoesNotExist:
            return Response({'error': 'المادة غير موجودة'}, status=status.HTTP_404_NOT_FOUND)
        serializer = SubjectSerializer(subject, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        try:
            Subject.objects.get(pk=pk).delete()
            return Response({'success': True})
        except Subject.DoesNotExist:
            return Response({'error': 'المادة غير موجودة'}, status=status.HTTP_404_NOT_FOUND)


class BookListAPIView(ListAPIView):
    serializer_class = BookSerializer

    def get_queryset(self):
        qs = Book.objects.all()
        subject_id = self.request.query_params.get('subject')
        term = self.request.query_params.get('term')
        if subject_id:
            qs = qs.filter(subject_id=subject_id)
        if term:
            qs = qs.filter(term=term)
        return qs


class BookPageAPIView(RetrieveAPIView):
    serializer_class = BookPageSerializer

    def get_object(self):
        book_id = self.request.query_params.get('book')
        page_number = self.request.query_params.get('page')
        if not book_id or not page_number:
            raise NotFound("book and page parameters are required")
        try:
            return BookPage.objects.get(book_id=book_id, page_number=page_number)
        except BookPage.DoesNotExist:
            raise NotFound("Page not found")


class PageSummaryListAPIView(ListAPIView):
    serializer_class = PageSummarySerializer

    def get_queryset(self):
        book_page_id = self.request.query_params.get('page')
        if not book_page_id:
            return PageSummary.objects.none()
        return PageSummary.objects.filter(book_page_id=book_page_id)


class PageSummaryPageAPIView(RetrieveAPIView):
    serializer_class = PageSummaryPageSerializer

    def get_object(self):
        summary_id = self.request.query_params.get('summary')
        page_order = self.request.query_params.get('page')
        if not summary_id or not page_order:
            raise NotFound("summary and page parameters are required")
        try:
            return PageSummaryPage.objects.get(summary_id=summary_id, page_order=page_order)
        except PageSummaryPage.DoesNotExist:
            raise NotFound("Summary page not found")


def book_page_html_view(request, page_number):
    book_id = request.GET.get('book')
    qs = BookPage.objects.filter(page_number=page_number)
    if book_id:
        qs = qs.filter(book_id=book_id)
    page = qs.first()
    if not page:
        return HttpResponse("""<html dir="rtl"><body style="display:flex;align-items:center;
justify-content:center;height:100vh;margin:0;font-family:Cairo,Tajawal,sans-serif;background:#fafafa;">
<div style="text-align:center;color:#888;padding:32px;">
  <div style="font-size:48px;margin-bottom:16px;">📄</div>
  <p style="font-size:18px;margin:0;">سيتم إضافة هذه الصفحة قريباً</p>
</div></body></html>""")

    html = page.content_html
    viewport_meta = '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes">'
    if '<head>' in html:
        html = html.replace('<head>', f'<head>{viewport_meta}', 1)
    else:
        html = viewport_meta + html
    return HttpResponse(html)


_COMING_SOON_HTML = """<script>window.totalPages=1;</script>
<html dir="rtl"><body style="display:flex;align-items:center;justify-content:center;
height:100vh;margin:0;font-family:Cairo,Tajawal,sans-serif;background:#fafafa;">
<div style="text-align:center;color:#888;padding:32px;">
  <div style="font-size:48px;margin-bottom:16px;">📚</div>
  <p style="font-size:18px;margin:0;">سيتم إضافة هذا الملخص قريباً</p>
</div></body></html>"""

def summary_page_html_view(request):
    book_id = request.GET.get("book")
    page_number = request.GET.get("page")
    summary_type = request.GET.get("type")
    summary_page = request.GET.get("summary_page", 1)

    if not all([book_id, page_number, summary_type]):
        return HttpResponse(_COMING_SOON_HTML)

    try:
        page_number = int(page_number)
        summary_type = int(summary_type)
        summary_page = int(summary_page)
    except (ValueError, TypeError):
        return HttpResponse(_COMING_SOON_HTML)

    book_page = BookPage.objects.filter(book_id=book_id, page_number=page_number).first()
    if not book_page:
        return HttpResponse(_COMING_SOON_HTML)

    summary = PageSummary.objects.filter(book_page=book_page, summary_type=summary_type).first()
    if not summary:
        return HttpResponse(_COMING_SOON_HTML)

    page = PageSummaryPage.objects.filter(summary=summary, page_order=summary_page).first()
    if not page:
        return HttpResponse(_COMING_SOON_HTML)

    total_pages = PageSummaryPage.objects.filter(summary=summary).count()
    navigation = f"""<script>
        window.hasNext = {str(summary_page < total_pages).lower()};
        window.hasPrev = {str(summary_page > 1).lower()};
        window.totalPages = {total_pages};
    </script>"""

    return HttpResponse(navigation + page.content_html)
