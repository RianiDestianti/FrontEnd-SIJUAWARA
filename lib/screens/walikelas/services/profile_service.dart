import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/models/types/profile.dart';

class ProfileService {
  static Future<Profile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '';

    final roleLabel = switch (role) {
      '3' => 'Wali Kelas',
      '4' => 'Kaprog',
      _ => 'Unknown',
    };

    return Profile(
      name: prefs.getString('name') ?? 'Unknown',
      role: roleLabel,
      nip: prefs.getString('walikelas_id') ?? 'Unknown',
      username: prefs.getString('name') ?? 'Unknown',
      email: prefs.getString('email') ?? 'Unknown',
      joinDate: prefs.getString('joinDate') ?? 'Unknown',
    );
  }

  /// Calls the API logout endpoint then clears all local session data.
  static Future<void> logout() async {
    try {
      await ApiClient.post('logout');
    } catch (_) {
      // Best-effort — clear session regardless
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}