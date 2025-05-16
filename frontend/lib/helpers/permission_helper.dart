import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // 권한 거부 시 다시 요청
      final shouldShowRationale = await Permission.location.status.isPermanentlyDenied;
      
      if (shouldShowRationale) {
        // 권한이 필요한 이유를 설명하고 다시 요청
        return await Permission.location.request().isGranted;
      }
      
      return false;
    } else if (status.isPermanentlyDenied) {
      // 영구 거부 시 설정 화면으로 이동
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<void> showPermissionRationale(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한이 필요합니다'),
        content: const Text(
          '위치 권한이 필요합니다. 위치 권한을 허용해 주시면 위치 기반 서비스를 이용하실 수 있습니다.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await requestLocationPermission();
            },
            child: const Text('설정'),
          ),
        ],
      ),
    );
  }
}
