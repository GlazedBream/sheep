from django.db import migrations

def create_initial_emotions(apps, schema_editor):
    Emotion = apps.get_model('diaries', 'Emotion')
    
    initial_emotions = [
        {'emotion_label': 'Happy', 'emoji': '😀', 'order': 1},
        {'emotion_label': 'Neutral', 'emoji': '😐', 'order': 2},
        {'emotion_label': 'Sad', 'emoji': '😢', 'order': 3},
        {'emotion_label': 'Angry', 'emoji': '😡', 'order': 4},
        {'emotion_label': 'Surprised', 'emoji': '😲', 'order': 5},
        {'emotion_label': 'Sleepy', 'emoji': '😴', 'order': 6},
    ]
    
    for emotion_data in initial_emotions:
        Emotion.objects.create(**emotion_data)

class Migration(migrations.Migration):
    dependencies = [
        ('diaries', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(create_initial_emotions),
    ]
