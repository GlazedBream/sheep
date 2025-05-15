from celery import shared_task
from ai_models.diary_generator.diary_generator import process_event, generate_diary

@shared_task(bind=True)
def generate_diary_task(self, event_data):
    try:
        processed_event = process_event(event_data)
        diary = generate_diary([processed_event])
        return {
            "status": "SUCCESS",
            "diary": diary,
            "event_id": event_data.get("event_id")
        }
    except Exception as e:
        return {
            "status": "FAILURE",
            "error": str(e),
            "event_id": event_data.get("event_id")
        }

