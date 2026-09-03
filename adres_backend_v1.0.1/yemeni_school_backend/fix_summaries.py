"""
سكريبت إصلاح الفهرسة:
1. يضيف BookPage الناقصة (بصفحة "قريباً") حتى تتمكن الملخصات من الارتباط بها
2. يضيف PageSummary + PageSummaryPage لكل صفحة لها ملف ملخص
3. يتجنب التكرار
"""
import os, re, sys, django

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from curriculum.models import Book, BookPage, PageSummary, PageSummaryPage

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'summaries')

COMING_SOON_HTML = """<!DOCTYPE html><html dir="rtl"><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
</head><body style="display:flex;align-items:center;justify-content:center;
height:100vh;margin:0;font-family:Cairo,Tajawal,sans-serif;background:#fafafa;">
<div style="text-align:center;color:#888;">
<div style="font-size:48px;margin-bottom:16px;">📄</div>
<p style="font-size:18px;margin:0;">سيتم إضافة هذه الصفحة قريباً</p>
</div></body></html>"""


def parse_pages_from_filename(filename):
    """استخراج أرقام الصفحات من اسم الملف مثل 8-9-10.html -> [8,9,10]"""
    name = re.sub(r'\.html$', '', filename, flags=re.IGNORECASE)
    # أخذ الجزء قبل أي underscore (مثل 110_2 -> 110)
    name = name.split('_')[0]
    parts = name.split('-')
    nums = []
    for p in parts:
        try:
            nums.append(int(p.strip()))
        except ValueError:
            pass
    if len(nums) == 0:
        return []
    if len(nums) == 1:
        return nums
    # نطاق من أول رقم لآخر رقم
    return list(range(nums[0], nums[-1] + 1))


def build_file_map(folder):
    """بناء خريطة: رقم الصفحة -> قائمة مسارات الملفات (مرتبة)"""
    file_map = {}
    if not os.path.exists(folder):
        return file_map
    for f in sorted(os.listdir(folder)):
        if not f.lower().endswith('.html'):
            continue
        pages = parse_pages_from_filename(f)
        for p in pages:
            file_map.setdefault(p, []).append(os.path.join(folder, f))
    return file_map


def fix_summaries(book, summary_type, folder_name):
    folder = os.path.join(BASE, folder_name)
    file_map = build_file_map(folder)

    if not file_map:
        print(f'  ⚠️  المجلد فارغ أو غير موجود: {folder}')
        return

    print(f'\n=== ملخص {summary_type} ({folder_name}) - {len(file_map)} صفحة مغطاة ===')

    added_pages = 0
    added_summaries = 0
    skipped = 0

    for page_num in sorted(file_map.keys()):
        file_paths = file_map[page_num]

        # 1. تأكد من وجود BookPage (أنشئها إذا ناقصة)
        book_page, bp_created = BookPage.objects.get_or_create(
            book=book,
            page_number=page_num,
            defaults={'content_html': COMING_SOON_HTML}
        )
        if bp_created:
            print(f'  📄 أضفت BookPage ناقصة: صفحة {page_num}')
            added_pages += 1

        # 2. تأكد من وجود PageSummary
        summary, ps_created = PageSummary.objects.get_or_create(
            book_page=book_page,
            summary_type=summary_type
        )

        # 3. إذا عنده صفحات مسبقاً، تجاوز
        if not ps_created and summary.pages.exists():
            skipped += 1
            continue

        # 4. أضف PageSummaryPage من الملفات
        for order, path in enumerate(file_paths, start=1):
            with open(path, 'r', encoding='utf-8', errors='replace') as f:
                html = f.read()
            PageSummaryPage.objects.create(
                summary=summary,
                page_order=order,
                content_html=html
            )
        added_summaries += 1
        print(f'  ✅ صفحة {page_num}: {len(file_paths)} ملف')

    print(f'  BookPages أضيفت: {added_pages}')
    print(f'  ملخصات أضيفت: {added_summaries}')
    print(f'  تجاوزت (موجودة): {skipped}')


if __name__ == '__main__':
    # جلب الكتاب الأول (رياضيات فصل أول)
    book = Book.objects.first()
    if not book:
        print('❌ لا يوجد كتاب في DB')
        sys.exit(1)

    print(f'الكتاب: {book.title} (ID={book.id})')

    fix_summaries(book, summary_type=1, folder_name='summary1')
    fix_summaries(book, summary_type=2, folder_name='summary2')

    print('\n✅ اكتمل الإصلاح')
