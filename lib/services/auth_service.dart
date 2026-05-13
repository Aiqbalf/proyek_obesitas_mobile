import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService — disesuaikan dengan ApiController.php (Laravel Sanctum)
///
/// Response login/register dari Laravel:
/// {
///   "message": "Login berhasil",
///   "token": "1|abc123...",
///   "user": { "id": "1", "name": "...", "email": "...", "role": "user" }
/// }
///
/// Response GET /api/user:
/// { "id": 1, "name": "...", "email": "...", "role": "user", ... }
class AuthService {
  // ─────────────────────────────────────────────
  // BASE URL — ganti sesuai environment kamu
  // ────────────────────────────────────────────
  
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  // static const String _baseUrl = 'http://192.168.180.40:8000/api';
  // static const String _baseUrl = 'http://10.10.180.40:8000/api'; // untuk broser
  // Emulator Android  → http://10.0.2.2:8000/api
  // Device fisik      → http://192.168.x.x:8000/api  (IP laptop di jaringan yang sama)
  // Staging/Produksi  → https://yourdomain.com/api

  // ─────────────────────────────────────────────
  // KEY SharedPreferences
  // ─────────────────────────────────────────────
  static const String _keyIsLogin = 'isLogin';
  static const String _keyToken   = 'token';
  static const String _keyUser    = 'user'; // cache JSON string data user

  // ══════════════════════════════════════════════
  // REGISTER
  // POST /api/register
  // Body  : { name, email, password, password_confirmation }
  // Return: { 'success': bool, 'message': String, 'user': Map? }
  // ══════════════════════════════════════════════
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _publicHeaders(),
        body: json.encode({
          'name'                 : name,
          'email'                : email,
          'password'             : password,
          'password_confirmation': password, // wajib karena Laravel pakai 'confirmed'
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // Register langsung dapat token — simpan sesi sekalian
        final token = data['token'] as String?;
        if (token != null) {
          await _saveSession(token: token, userData: data['user']);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Registrasi berhasil',
          'user'   : data['user'],
        };
      } else {
        // 422 Validation error: Laravel kirim { "message": "...", "errors": {...} }
        final errors = data['errors'] as Map<String, dynamic>?;
        String msg = data['message'] ?? 'Registrasi gagal';
        if (errors != null && errors.isNotEmpty) {
          // Ambil pesan error pertama dari validasi
          msg = (errors.values.first as List).first.toString();
        }
        return {'success': false, 'message': msg};
      }
    } on Exception catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ══════════════════════════════════════════════
  // LOGIN
  // POST /api/login
  // Body  : { email, password }
  // Return: { 'success': bool, 'message': String, 'user': Map? }
  // ══════════════════════════════════════════════
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: _publicHeaders(),
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = data['token'] as String?;
        if (token == null) {
          return {'success': false, 'message': 'Token tidak ditemukan di response'};
        }

        // Simpan token + cache user
        await _saveSession(token: token, userData: data['user']);

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'user'   : data['user'],
        };
      } else {
        // 401 → Email/password salah | 403 → Bukan role 'user'
        return {
          'success': false,
          'message': data['message'] ?? 'Login gagal',
        };
      }
    } on Exception catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
    }
  }

  // ══════════════════════════════════════════════
  // LOGOUT
  // POST /api/logout  (butuh token)
  // ══════════════════════════════════════════════
  static Future<void> logout() async {
    final token = await getToken();

    // Best-effort: revoke token di server
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: _authHeaders(token),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Abaikan error jaringan — tetap hapus data lokal
      }
    }

    // Hapus semua data lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLogin);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // ══════════════════════════════════════════════
  // GET USER
  // GET /api/user  (butuh token, protected route)
  // Return: Map<String, dynamic>? — data user dari DB
  //
  // Kolom yang dikembalikan $request->user():
  //   id, name, email, email_verified_at, role,
  //   created_at, updated_at, (+ kolom lain di tabel users)
  // ══════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return _getCachedUser();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body) as Map<String, dynamic>;
        await _cacheUser(userData);     // perbarui cache
        return userData;
      } else if (response.statusCode == 401) {
        // Token expired / tidak valid → logout otomatis
        await logout();
        return null;
      } else {
        return _getCachedUser();        // fallback ke cache
      }
    } on Exception {
      return _getCachedUser();          // tidak ada koneksi → pakai cache
    }
  }

  // ══════════════════════════════════════════════
  // GETTER SEDERHANA
  // ══════════════════════════════════════════════
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // ══════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════

  /// Simpan token + isLogin + cache user sekaligus
  static Future<void> _saveSession({
    required String token,
    dynamic userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLogin, true);
    await prefs.setString(_keyToken, token);
    if (userData != null) {
      await _cacheUser(Map<String, dynamic>.from(userData as Map));
    }
  }

  static Future<void> _cacheUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, json.encode(userData));
  }

  static Future<Map<String, dynamic>?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_keyUser);
    if (cached == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(cached) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Header untuk public routes (tanpa token)
  static Map<String, String> _publicHeaders() => {
    'Content-Type': 'application/json',
    'Accept'      : 'application/json',
  };

  /// Header untuk protected routes (dengan Bearer token)
  static Map<String, String> _authHeaders(String token) => {
    'Content-Type' : 'application/json',
    'Accept'       : 'application/json',
    'Authorization': 'Bearer $token',
  };
}