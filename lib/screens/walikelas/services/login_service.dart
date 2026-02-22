import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/firebase/tokenfcm.dart';

class LoginResult {
  final bool success;
  final String? role;
  final String? message;

  const LoginResult({required this.success, this.role, this.message});
}

class LoginService {
  static Future<LoginResult> login(String nip, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {'Accept': 'application/json'},
        body: {'nip': nip, 'password': password},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Detect missing token — means HasApiTokens is not set up on backend
        final token = data['token']?.toString() ?? '';
        if (token.isEmpty) {
          return const LoginResult(
            success: false,
            message: 'Server tidak mengembalikan token. Pastikan Sanctum sudah dikonfigurasi di Laravel.',
          );
        }

        await _saveSession(data, nip, password);
        await FcmTokenService.instance.syncToken();
        return LoginResult(success: true, role: data['role'].toString());
      }

      return LoginResult(
        success: false,
        message: data['message'] ?? 'Gagal masuk',
      );
    } catch (e) {
      return LoginResult(success: false, message: 'Terjadi kesalahan: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('logout');
    } catch (_) {
      // Best-effort
    } finally {
      await _clearSession();
    }
  }

  static Future<void> _saveSession(
    Map<String, dynamic> data,
    String nip,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final detail = data['detail'] as Map<String, dynamic>? ?? {};
    final user = data['user'] as Map<String, dynamic>? ?? {};

    // Save sequentially — guarantees token is written before returning
    await prefs.setString('sanctum_token', data['token']?.toString() ?? '');
    await prefs.setString('walikelas_id', detail['nip_walikelas']?.toString() ?? '');
    await prefs.setString('role', data['role'].toString());
    await prefs.setString('name', detail['nama_walikelas'] ?? user['username'] ?? '');
    await prefs.setString('email', user['email'] ?? 'Unknown');
    await prefs.setString('phone', 'Unknown');
    await prefs.setString('joinDate', detail['created_at'] ?? 'Unknown');
    await prefs.setString('id_kelas', detail['id_kelas'] ?? 'Unknown');
    await prefs.setString('jurusan', detail['jurusan'] ?? 'Unknown');
    await prefs.setString('biometric_nip', nip);
    await prefs.setString('biometric_password', password);
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sanctum_token');
  }

  static Future<({String nip, String password})?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('biometric_nip') ?? '';
    final password = prefs.getString('biometric_password') ?? '';
    if (nip.isEmpty || password.isEmpty) return null;
    return (nip: nip, password: password);
  }
}