import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emergency_service.dart';

class ServiceCacheManager {
  static const _boxName = 'serviceCache';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(EmergencyServiceAdapter().typeId)) {
      Hive.registerAdapter(EmergencyServiceAdapter());
    }
    if (!Hive.isAdapterRegistered(ServiceTypeAdapter().typeId)) {
      Hive.registerAdapter(ServiceTypeAdapter());
    }
    await Hive.openBox<Map>(_boxName);
  }

  static String _generateCacheKey(Map<String, dynamic> params) {
    return params.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  static Future<List<EmergencyService>?> getCachedResult(Map<String, dynamic> params) async {
    debugPrint('Loading cached data...');
    final box = Hive.box<Map>(_boxName);
    final key = _generateCacheKey(params);
    final entry = box.get(key);

    if (entry != null && entry['timestamp'] is DateTime) {
      final cachedTime = entry['timestamp'] as DateTime;
      final now = DateTime.now();
      final age = now.difference(cachedTime);

      if (age.inHours < 1) {
        debugPrint('Cache hit and still valid');
        return (entry['data'] as List).cast<EmergencyService>();
      } else {
        debugPrint('Cache expired');
        await box.delete(key);
      }
    }

    debugPrint('No valid cache found');
    return null;
  }

  static Future<void> cacheResult(Map<String, dynamic> params, List<EmergencyService> result) async {
    debugPrint("Caching emergency service...");
    final box = Hive.box<Map>(_boxName);
    final key = _generateCacheKey(params);
    await box.put(key, {
      'data': result,
      'timestamp': DateTime.now(),
    });
  }
}
