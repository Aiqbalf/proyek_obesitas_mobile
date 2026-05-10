import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // 🔥 GANTI INI DENGAN IP LAPTOP KAMU (cek dengan ipconfig di cmd)
  static const String localIP = "192.168.0.100";

  // 🔥 AUTO BASE URL → ke Laravel
  static String get baseUrl {
  if (kIsWeb) {
    return "http://localhost:8000/api"; // 🔥 ganti ini
  } else if (Platform.isAndroid) {
    return "http://$localIP:8000/api"; // 🔥 ganti ini
  } else {
    return "http://$localIP:8000/api"; // 🔥 ganti ini
  }
}

  // =======================
  // 🔐 LOGIN
  // =======================
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
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_name', data['user']['name'] ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        await prefs.setString('user_role', data['user']['role'] ?? 'user');
        await prefs.setString('user_id', data['user']['id'].toString());
      }

      return {
        "status": response.statusCode,
        "data": data,
      };

    } catch (e) {
      print("LOGIN ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Tidak bisa konek ke server"},
      };
    }
  }

  // =======================
  // 📝 REGISTER
  // =======================
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
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": password,
        }),
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      final data = jsonDecode(response.body);

      // 🔥 simpan token setelah register — user langsung masuk tanpa login ulang
      if (response.statusCode == 201 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_name', data['user']['name'] ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        await prefs.setString('user_role', data['user']['role'] ?? 'user');
        await prefs.setString('user_id', data['user']['id'].toString());
      }

      return {
        "status": response.statusCode,
        "data": data,
      };

    } catch (e) {
      print("REGISTER ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Tidak bisa konek ke server"},
      };
    }
  }

  // =======================
  // 🤖 CHAT AI → Laravel ChatController
  // =======================
  static Future<Map<String, dynamic>> chat(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer",
        },
        body: jsonEncode({"message": message}),
      );

      print("CHAT STATUS: ${response.statusCode}");
      print("CHAT BODY: ${response.body}");

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };

    } catch (e) {
      print("CHAT ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Tidak bisa konek ke server"},
      };
    }
  }

  // =======================
  // 🚪 LOGOUT
  // =======================
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      await prefs.clear();
    } catch (e) {
      print("LOGOUT ERROR: $e");
      // tetap clear local data meski request gagal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // =======================
  // 🔑 GET TOKEN
  // =======================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =======================
  // 👤 GET USER INFO LOKAL
  // =======================
  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id':    prefs.getString('user_id') ?? '',
      'name':  prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'role':  prefs.getString('user_role') ?? 'user',
    };
  }

  // =======================
  // ✅ CEK SUDAH LOGIN
  // =======================
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // =======================
  // 🌐 REQUEST HELPER (untuk endpoint lain yang butuh auth)
  // =======================
  static Future<Map<String, dynamic>> authGet(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("GET $endpoint STATUS: ${response.statusCode}");

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };

    } catch (e) {
      print("GET ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Tidak bisa konek ke server"},
      };
    }
  }

  static Future<Map<String, dynamic>> authPost(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("POST $endpoint STATUS: ${response.statusCode}");

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };

    } catch (e) {
      print("POST ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Tidak bisa konek ke server"},
      };
    }
  }

   // =======================
// 📰 GET ARTICLES
// =======================
static Future<List<dynamic>> getArticles() async {

  try {

    final response = await http.get(
      Uri.parse("$baseUrl/articles"),
    );

    print("ARTICLE STATUS: ${response.statusCode}");
    print("ARTICLE BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      // jika array langsung
      if (data is List) {
        return data;
      }

      // jika object dengan key data
      if (data is Map && data.containsKey("data")) {
        return data["data"];
      }

      // jika object dengan key articles
      if (data is Map && data.containsKey("articles")) {
        return data["articles"];
      }
    }

    return [];

  } catch (e) {

    print("GET ARTICLE ERROR: $e");

    return [];
  }
}

}