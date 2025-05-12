from django.urls import path
from . import views

urlpatterns = [
    path('process-images/', views.process_images, name='process_images'),
    path('events/', views.create_event, name='create_event'),
]
