import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // ── Ganti dengan IP laptop kamu (cek dengan ipconfig di cmd) ──
  static const String localIP = "10.10.187.30";

  // ── Base URL otomatis sesuai platform ──
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api"; // Web (Chrome) pakai localhost
    } else if (Platform.isAndroid || Platform.isIOS) {
      return "http://$localIP:8000/api";  // HP fisik pakai IP laptop
    } else {
      return "http://$localIP:8000/api";
    }
  }

  // ══════════════════════════════════════
  //  LOGIN
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");
      print("LOGIN URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',      data['token']);
        await prefs.setString('user_name',  data['user']['name']  ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        await prefs.setString('user_role',  data['user']['role']  ?? 'user');
        await prefs.setString('user_id',    data['user']['id'].toString());
      }

      return {"status": response.statusCode, "data": data};
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {"status": 500, "data": {"message": "Tidak bisa konek ke server"}};
    }
  }

  // ══════════════════════════════════════
  //  REGISTER
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/register");
      print("REGISTER URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name":                  name,
          "email":                 email,
          "password":              password,
          "password_confirmation": password,
        }),
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',      data['token']);
        await prefs.setString('user_name',  data['user']['name']  ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        await prefs.setString('user_role',  data['user']['role']  ?? 'user');
        await prefs.setString('user_id',    data['user']['id'].toString());
      }

      return {"status": response.statusCode, "data": data};
    } catch (e) {
      print("REGISTER ERROR: $e");
      return {"status": 500, "data": {"message": "Tidak bisa konek ke server"}};
    }
  }

  // ══════════════════════════════════════
  //  CHAT AI
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> chat(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"message": message}),
      );

      print("CHAT STATUS: ${response.statusCode}");
      print("CHAT BODY: ${response.body}");

      return {"status": response.statusCode, "data": jsonDecode(response.body)};
    } catch (e) {
      print("CHAT ERROR: $e");
      return {"status": 500, "data": {"message": "Tidak bisa konek ke server"}};
    }
  }

  // ══════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept":        "application/json",
        },
      );

      await prefs.clear();
    } catch (e) {
      print("LOGOUT ERROR: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // ══════════════════════════════════════
  //  GET TOKEN
  // ══════════════════════════════════════
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ══════════════════════════════════════
  //  GET USER INFO LOKAL
  // ══════════════════════════════════════
  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id':    prefs.getString('user_id')    ?? '',
      'name':  prefs.getString('user_name')  ?? '',
      'email': prefs.getString('user_email') ?? '',
      'role':  prefs.getString('user_role')  ?? 'user',
    };
  }

  // ══════════════════════════════════════
  //  CEK SUDAH LOGIN
  // ══════════════════════════════════════
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ══════════════════════════════════════
  //  AUTH GET (endpoint lain yang butuh token)
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> authGet(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("GET $endpoint STATUS: ${response.statusCode}");

      return {"status": response.statusCode, "data": jsonDecode(response.body)};
    } catch (e) {
      print("GET ERROR: $e");
      return {"status": 500, "data": {"message": "Tidak bisa konek ke server"}};
    }
  }

  // ══════════════════════════════════════
  //  AUTH POST
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> authPost(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("POST $endpoint STATUS: ${response.statusCode}");

      return {"status": response.statusCode, "data": jsonDecode(response.body)};
    } catch (e) {
      print("POST ERROR: $e");
      return {"status": 500, "data": {"message": "Tidak bisa konek ke server"}};
    }
  }

  // ══════════════════════════════════════
  //  GET ARTICLES
  // ══════════════════════════════════════
  static Future<List<dynamic>> getArticles() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/articles"),
        headers: {"Accept": "application/json"},
      );

      print("ARTICLE STATUS: ${response.statusCode}");
      print("ARTICLE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List)                            return data;
        if (data is Map && data['data'] != null)     return data['data'];
        if (data is Map && data['articles'] != null) return data['articles'];
      }

      return [];
    } catch (e) {
      print("GET ARTICLE ERROR: $e");
      return [];
    }
  }

  // ══════════════════════════════════════
  //  UPDATE PROFILE
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    String name,
    String email,
    String password,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final body = <String, dynamic>{
        "id"   : userId,
        "name" : name,
        "email": email,
      };

      if (password.isNotEmpty) {
        body["password"] = password;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/update-profile"),
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      return {
        "status": response.statusCode,
        "data":   data,
      };
    } catch (e) {
      return {
        "status": 500,
        "data":   {"message": "Tidak bisa konek ke server"},
      };
    }
  }

  // ══════════════════════════════════════
  //  GET PREDICTION HISTORY
  //  ✅ FIX: pakai baseUrl bukan hardcode 127.0.0.1
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> getPredictionHistory(
    String userId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/obesity/history?user_id=$userId");

      print("HISTORY URL: $url");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        url,
        headers: {
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("HISTORY STATUS: ${response.statusCode}");
      print("HISTORY BODY: ${response.body}");

      final data = jsonDecode(response.body);

      return {
        'status': response.statusCode,
        'data':   data,
      };
    } catch (e) {
      return {
        'status': 500,
        'data':   {'message': e.toString()},
      };
    }
  }

  // ══════════════════════════════════════
  //  GET USER (Fetch from API)
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>?> getUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user"),
        headers: {
          "Accept":        "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Update cache
        final prefs = await SharedPreferences.getInstance();
        if (userData['name'] != null) await prefs.setString('user_name', userData['name']);
        if (userData['email'] != null) await prefs.setString('user_email', userData['email']);
        if (userData['role'] != null) await prefs.setString('user_role', userData['role']);
        
        return userData;
      } else if (response.statusCode == 401) {
        await logout();
        return null;
      }
    } catch (e) {
      print("GET USER ERROR: $e");
    }
    
    // Fallback: return cached user data if network fails or endpoint doesn't exist
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_name');
    if (cachedName != null && cachedName.isNotEmpty) {
      return {
        'id':    prefs.getString('user_id'),
        'name':  cachedName,
        'email': prefs.getString('user_email'),
        'role':  prefs.getString('user_role') ?? 'user',
      };
    }
    
    return null;
  }

  // ══════════════════════════════════════
  //  PREDICT OBESITY
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> predictObesity({
    required double usia,
    required double tinggi,
    required double berat,
    required String jenisKelamin,
    required String alkohol,
    required String kaloriTinggi,
    required String monitoring,
    required String merokok,
    required String riwayat,
    required String ngamil,
    required String transport,
    required double sayur,
    required int makanHarian,
    required double konsumsiAir,
    required double aktivitas,
    required double waktuLayar,
  }) async {
    final payload = {
      'usia':             usia,
      'tinggi':           tinggi,
      'berat':            berat,
      'jenis_kelamin':    jenisKelamin,
      'alkohol':          alkohol,
      'kalori_tinggi':    kaloriTinggi,
      'monitoring':       monitoring,
      'merokok':          merokok,
      'riwayat_keluarga': riwayat,
      'ngemil':           ngamil,
      'transportasi':     transport,
      'konsumsi_sayur':   sayur,
      'makan_harian':     makanHarian,
      'konsumsi_air':     konsumsiAir,
      'aktivitas_fisik':  aktivitas,
      'waktu_layar':      waktuLayar,
    };

    print('=== PAYLOAD ===');
    print(jsonEncode(payload));
    print('=== URL: $baseUrl/predict-obesity ===');

    final response = await http.post(
      Uri.parse('$baseUrl/predict-obesity'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('=== RESPONSE ${response.statusCode} ===');
    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal prediksi: ${response.statusCode} ${response.body}');
    }
  }
}