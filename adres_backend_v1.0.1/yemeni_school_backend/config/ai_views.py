import json
import os
import urllib.request
import urllib.error
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST


@csrf_exempt
@require_POST
def ai_explain_view(request):
    """
    POST /api/ai/explain/
    Body: { "text": "...", "subject": "رياضيات", "grade": "التاسع" }
    Proxies request to Groq API using server-side key.
    """
    try:
        body = json.loads(request.body)
    except (json.JSONDecodeError, ValueError):
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    text = body.get('text', '').strip()
    subject = body.get('subject', 'الرياضيات')
    grade = body.get('grade', 'التاسع')
    student_name = body.get('student_name', '').strip()

    if not text:
        return JsonResponse({'error': 'text is required'}, status=400)

    api_key = os.environ.get('GROQ_API_KEY', '')
    if not api_key:
        return JsonResponse({'error': 'AI service not configured'}, status=503)

    name_part = f" تحدث مع الطالب باسمه '{student_name}' في بداية الشرح." if student_name else ""
    system_prompt = f"أنت معلم {subject} متخصص لطلاب الصف {grade} في اليمن.{name_part} أجب بالعربية الفصحى البسيطة، بشكل منظم ومختصر."
    user_message = f'اشرح النص التالي بطريقة مبسطة مع أمثلة عملية:\n"{text[:3000]}"'

    payload = json.dumps({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_message},
        ],
        'max_tokens': 1024,
        'temperature': 0.7,
    }).encode('utf-8')

    req = urllib.request.Request(
        'https://api.groq.com/openai/v1/chat/completions',
        data=payload,
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'curl/7.88.1',
        },
        method='POST',
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            result = data['choices'][0]['message']['content']
            return JsonResponse({'result': result})
    except urllib.error.HTTPError as e:
        return JsonResponse({'error': f'AI service error: {e.code}'}, status=502)
    except Exception as e:
        return JsonResponse({'error': 'AI service unavailable'}, status=503)
