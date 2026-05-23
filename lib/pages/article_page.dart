import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ArticlePage extends StatefulWidget {
  final bool embedded;
  const ArticlePage({super.key, this.embedded = false});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  static const Color _green700   = Color(0xFF047857);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _green50    = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral100 = Color(0xFFF3F4F6);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral900 = Color(0xFF111827);

  late Future<List<dynamic>> _futureArticles;

  @override
  void initState() {
    super.initState();
    _futureArticles = ApiService.getArticles();
  }

  Future<void> _refresh() async {
    setState(() => _futureArticles = ApiService.getArticles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutral50,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          'Artikel Kesehatan',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _neutral900,
              letterSpacing: -0.3),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _neutral200),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureArticles,
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: _green700, strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  Text('Memuat artikel...',
                      style: TextStyle(
                          fontSize: 13,
                          color: _neutral400,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                          color: _neutral100, shape: BoxShape.circle),
                      child: const Icon(Icons.wifi_off_rounded,
                          color: _neutral400, size: 38),
                    ),
                    const SizedBox(height: 20),
                    const Text('Gagal memuat artikel',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _neutral900)),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: _neutral400),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final articles = snapshot.data ?? [];

          // ── Empty ──
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: _green50, shape: BoxShape.circle),
                    child: const Icon(Icons.article_rounded,
                        color: _green700, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada artikel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _neutral900)),
                  const SizedBox(height: 8),
                  const Text('Artikel akan segera ditambahkan.',
                      style: TextStyle(fontSize: 13, color: _neutral400)),
                ],
              ),
            );
          }

          // ── List ──
          return RefreshIndicator(
            onRefresh: _refresh,
            color: _green700,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final item = articles[index];
                // Featured card untuk item pertama
                if (index == 0) {
                  return _FeaturedArticleCard(
                    item: item,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => _DetailPage(article: item)),
                    ),
                  );
                }
                return _ArticleCard(
                  item: item,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _DetailPage(article: item)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Featured Article Card (item pertama — lebih besar)
// ─────────────────────────────────────────────
class _FeaturedArticleCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _FeaturedArticleCard({required this.item, required this.onTap});

  static const Color _green700   = Color(0xFF047857);
  static const Color _green900   = Color(0xFF064E3B);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _green50    = Color(0xFFF0FDF4);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral900 = Color(0xFF111827);

  String _imageUrl() {
    if (item['gambar'] != null && item['gambar'].toString().isNotEmpty) {
      return ApiService.getImageUrl(item['gambar'].toString());
    }
    return 'https://picsum.photos/seed/${item['_id'] ?? item['id'] ?? '1'}/800/400';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _neutral200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar dengan overlay gradient + badge TERBARU ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: _NetworkImageWithFallback(
                    url: _imageUrl(),
                    height: 200,
                  ),
                ),
                // Badge "Terbaru"
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _green700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text('TERBARU',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  if (item['kategori'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _green50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _green100),
                      ),
                      child: Text(
                        item['kategori'].toString(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _green700),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Judul
                  Text(
                    item['judul'] ?? 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _neutral900,
                        letterSpacing: -0.3,
                        height: 1.25),
                  ),

                  const SizedBox(height: 8),

                  // Ringkasan
                  if (item['ringkasan'] != null &&
                      item['ringkasan'].toString().isNotEmpty)
                    Text(
                      item['ringkasan'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: _neutral400, height: 1.5),
                    ),

                  const SizedBox(height: 16),

                  // Footer
                  Row(
                    children: [
                      if (item['penulis'] != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _green50,
                            shape: BoxShape.circle,
                            border: Border.all(color: _green100),
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 16, color: _green700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['penulis'].toString(),
                          style: const TextStyle(
                              fontSize: 12,
                              color: _neutral400,
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      _ReadButton(onTap: onTap),
                    ],
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

// ─────────────────────────────────────────────
//  Regular Article Card (horizontal layout)
// ─────────────────────────────────────────────
class _ArticleCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _ArticleCard({required this.item, required this.onTap});

  static const Color _green700   = Color(0xFF047857);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _green50    = Color(0xFFF0FDF4);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  String _imageUrl() {
    if (item['gambar'] != null && item['gambar'].toString().isNotEmpty) {
      return ApiService.getImageUrl(item['gambar'].toString());
    }
    return 'https://picsum.photos/seed/${item['_id'] ?? item['id'] ?? '1'}/400/300';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _neutral200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _NetworkImageWithFallback(
                url: _imageUrl(),
                width: 90,
                height: 90,
              ),
            ),

            const SizedBox(width: 12),

            // ── Konten ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  if (item['kategori'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _green100),
                      ),
                      child: Text(
                        item['kategori'].toString(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _green700),
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Judul
                  Text(
                    item['judul'] ?? 'Tanpa Judul',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _neutral900,
                        letterSpacing: -0.2,
                        height: 1.3),
                  ),

                  const SizedBox(height: 6),

                  // Footer
                  Row(
                    children: [
                      if (item['penulis'] != null) ...[
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: _neutral400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item['penulis'].toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: _neutral400),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _green50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _green100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Baca',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _green700)),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded,
                                size: 11, color: _green700),
                          ],
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────
class _ReadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF047857),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Baca',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            SizedBox(width: 5),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _NetworkImageWithFallback extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;

  const _NetworkImageWithFallback(
      {required this.url, this.width, this.height});

  static const Color _green50  = Color(0xFFF0FDF4);
  static const Color _green100 = Color(0xFFD1FAE5);
  static const Color _green700 = Color(0xFF047857);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: _green50,
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded,
              color: _green100, size: 32),
        ),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              width: width,
              height: height,
              color: const Color(0xFFE5E7EB),
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _green700),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  Detail Page
// ─────────────────────────────────────────────
class _DetailPage extends StatelessWidget {
  final dynamic article;
  const _DetailPage({required this.article});

  static const Color _green700   = Color(0xFF047857);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _green50    = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (article['gambar'] != null &&
            article['gambar'].toString().isNotEmpty)
        ? ApiService.getImageUrl(article['gambar'].toString())
        : 'https://picsum.photos/seed/${article['_id'] ?? '1'}/800/400';

    return Scaffold(
      backgroundColor: _neutral50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _green700,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _green50,
                      child: const Icon(Icons.article_rounded,
                          color: _green100, size: 64),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Konten ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  if (article['kategori'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _green50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _green100),
                      ),
                      child: Text(
                        article['kategori'].toString(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _green700),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Judul
                  Text(
                    article['judul'] ?? '',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _neutral900,
                        letterSpacing: -0.4,
                        height: 1.2),
                  ),

                  const SizedBox(height: 14),

                  // Penulis
                  Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _green50,
                        shape: BoxShape.circle,
                        border: Border.all(color: _green100),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 17, color: _green700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article['penulis'] ?? 'Admin',
                      style: const TextStyle(
                          fontSize: 13,
                          color: _neutral400,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  const Divider(color: _neutral200, height: 1),
                  const SizedBox(height: 20),

                  // Isi artikel
                  Text(
                    article['isi'] ?? '',
                    style: const TextStyle(
                        fontSize: 15,
                        color: _neutral600,
                        height: 1.8),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}