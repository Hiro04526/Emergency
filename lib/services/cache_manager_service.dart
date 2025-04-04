import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emergency_service.dart';

class ServiceCacheManager {
  static const _boxName = 'serviceCache';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(EmergencyServiceAdapter());
    Hive.registerAdapter(ServiceTypeAdapter());
    await Hive.openBox<List>(_boxName);
  }

  static String _generateCacheKey(Map<String, dynamic> params) {
    return params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  static Future<List<EmergencyService>?> getCachedResult(Map<String, dynamic> params) async {
    debugPrint('Loading cached data');
    final box = Hive.box<List>(_boxName);
    final key = _generateCacheKey(params);
    final rawList = box.get(key);
    return rawList?.cast<EmergencyService>();
  }

  static Future<void> cacheResult(Map<String, dynamic> params, List<EmergencyService> result) async {
    debugPrint("Caching emergency service...");
    final box = Hive.box<List>(_boxName);
    final key = _generateCacheKey(params);
    await box.put(key, result);
  }
}
