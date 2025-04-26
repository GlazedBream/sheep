import 'package:shared_preferences/shared_preferences.dart';

class EventSettings {
  // 이벤트 감지 설정
  double radiusMeters; // 이벤트 감지 반경 (미터)
  int minDurationMinutes; // 최소 체류 시간 (분)
  int checkIntervalMinutes; // 이벤트 감지 간격 (분)
  bool autoDetectEvents; // 자동 이벤트 감지 활성화 여부

  // 기본 설정
  EventSettings({
    this.radiusMeters = 500,
    this.minDurationMinutes = 30,
    this.checkIntervalMinutes = 5,
    this.autoDetectEvents = true,
  });

  // 설정 저장
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('event_radius_meters', radiusMeters);
    await prefs.setInt('event_min_duration_minutes', minDurationMinutes);
    await prefs.setInt('event_check_interval_minutes', checkIntervalMinutes);
    await prefs.setBool('event_auto_detect', autoDetectEvents);
  }

  // 설정 로드
  static Future<EventSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return EventSettings(
      radiusMeters: prefs.getDouble('event_radius_meters') ?? 500,
      minDurationMinutes: prefs.getInt('event_min_duration_minutes') ?? 30,
      checkIntervalMinutes: prefs.getInt('event_check_interval_minutes') ?? 5,
      autoDetectEvents: prefs.getBool('event_auto_detect') ?? true,
    );
  }
}
