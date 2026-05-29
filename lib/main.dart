import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  ApiService.testConnection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: const MaterialColor(0xFF4CAF50, <int, Color>{
          50: Color(0xFFE8F5E8),
          100: Color(0xFFC8E6C9),
          200: Color(0xFFA5D6A7),
          300: Color(0xFF81C784),
          400: Color(0xFF66BB6A),
          500: Color(0xFF4CAF50),
          600: Color(0xFF43A047),
          700: Color(0xFF388E3C),
          800: Color(0xFF2E7D32),
          900: Color(0xFF1B5E20),
        }),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      title: 'SiObe',
      home: const DashboardPage(),
    );
  }
}