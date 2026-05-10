import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'bmi_page.dart';
import 'chat_page.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {

  late Future<List<dynamic>> futureArticles;

  int _currentIndex = 0;

  // =======================
  // THEME
  // =======================
  static const Color primaryColor = Color(0xFF059669);
  static const Color surfaceColor = Color(0xFFF5F7FB);
  static const Color cardColor = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    futureArticles = ApiService.getArticles();
  }

  Future<void> refreshArticles() async {
    setState(() {
      futureArticles = ApiService.getArticles();
    });
  }

  // =======================
  // NAVIGATION
  // =======================
  void _onNavbarTap(int index) {

    setState(() => _currentIndex = index);

    switch (index) {

      // BERANDA
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
        break;

      // BMI
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BmiPage(),
          ),
        );
        break;

      // RIWAYAT
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fitur Riwayat masih pengembangan"),
          ),
        );
        break;

      // CHAT
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatPage(),
          ),
        );
        break;

      // PROFIL
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fitur Profil masih pengembangan"),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: surfaceColor,

      // =======================
      // APPBAR
      // =======================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        title: const Text(
          "Artikel Kesehatan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =======================
      // BODY
      // =======================
      body: FutureBuilder<List<dynamic>>(

        future: futureArticles,

        builder: (context, snapshot) {

          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ERROR
          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          final articles = snapshot.data ?? [];

          print("DATA ARTICLE:");
          print(articles);

          // EMPTY
          if (articles.isEmpty) {

            return const Center(
              child: Text(
                "Belum ada artikel",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }

          // SUCCESS
          return RefreshIndicator(

            onRefresh: refreshArticles,

            child: ListView.builder(

              padding: const EdgeInsets.all(16),

              itemCount: articles.length,

              itemBuilder: (context, index) {

                final item = articles[index];

                return Container(

                  margin: const EdgeInsets.only(bottom: 18),

                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // =======================
                      // IMAGE
                      // =======================
                      Container(
                        height: 180,
                        width: double.infinity,

                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),

                          image: DecorationImage(
                            image: NetworkImage(
                              item['gambar'] != null &&
                                      item['gambar'].toString().isNotEmpty
                                  ? item['gambar']
                                  : "https://picsum.photos/500/300",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // =======================
                            // CATEGORY
                            // =======================
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Text(
                                item['kategori'] ?? "Kesehatan",

                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // =======================
                            // TITLE
                            // =======================
                            Text(
                              item['judul'] ?? "Tanpa Judul",

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // =======================
                            // SUMMARY
                            // =======================
                            Text(
                              item['ringkasan'] ?? "",

                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.grey,
                                height: 1.5,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // =======================
                            // BUTTON
                            // =======================
                            SizedBox(
                              width: double.infinity,

                              child: ElevatedButton(

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),

                                onPressed: () {

                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder: (_) => DetailPage(
                                        article: item,
                                      ),
                                    ),
                                  );
                                },

                                child: const Text(
                                  "Baca Selengkapnya",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),

      // =======================
      // BOTTOM NAVIGATION
      // =======================
      bottomNavigationBar: Container(

        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: _currentIndex,

          selectedItemColor: primaryColor,
          unselectedItemColor: textSecondary,

          type: BottomNavigationBarType.fixed,

          elevation: 0,
          backgroundColor: cardColor,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),

          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),

          onTap: _onNavbarTap,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight_outlined),
              activeIcon: Icon(Icons.monitor_weight_rounded),
              label: 'Cek BMI',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'SiObe',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================
// DETAIL PAGE
// ======================================
class DetailPage extends StatelessWidget {

  final Map article;

  const DetailPage({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: Text(
          article['judul'] ?? "Detail Artikel",
        ),
      ),

      body: SingleChildScrollView(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            Container(
              height: 250,
              width: double.infinity,

              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    article['gambar'] != null &&
                            article['gambar'].toString().isNotEmpty
                        ? article['gambar']
                        : "https://picsum.photos/600/400",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // CATEGORY
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      article['kategori'] ?? "Kesehatan",

                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TITLE
                  Text(
                    article['judul'] ?? "",

                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // AUTHOR
                  Row(
                    children: [

                      const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        article['penulis'] ?? "Admin",

                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // CONTENT
                  Text(
                    article['isi'] ?? "",

                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}