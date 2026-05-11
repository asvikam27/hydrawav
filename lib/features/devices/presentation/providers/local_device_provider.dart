import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/device_model.dart';

final localDeviceProvider =
    StateNotifierProvider<LocalDeviceNotifier, List<DeviceInfo>>(
  (ref) => LocalDeviceNotifier(),
);

class LocalDeviceNotifier extends StateNotifier<List<DeviceInfo>> {
  LocalDeviceNotifier() : super([]) {
    loadDevices();
  }

  static const _key = "local_devices";

  Future<void> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => DeviceInfo.fromJson(e)).toList();
    }
  }

  Future<void> add(DeviceInfo device) async {
    state = [...state, device];
    await _save();
  }

  Future<void> remove(DeviceInfo device) async {
    state = state.where((d) => d.id != device.id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}