import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS — selaras dengan dashboard ObesityCheck
// ══════════════════════════════════════════════════════════════════════════════
class _T {
  // Brand (sama persis dengan dashboard)
  static const primary   = Color(0xFF047857); // emerald-700
  static const primaryL  = Color(0xFF059669); // emerald-600
  static const primaryBg = Color(0xFFECFDF5); // emerald-50
  static const primaryMd = Color(0xFFD1FAE5); // emerald-100

  // Neutral (sama dengan dashboard)
  static const ink     = Color(0xFF111827); // gray-900
  static const inkSub  = Color(0xFF374151); // gray-700
  static const muted   = Color(0xFF6B7280); // gray-500
  static const soft    = Color(0xFF9CA3AF); // gray-400
  static const border  = Color(0xFFE5E7EB); // gray-200
  static const surface = Color(0xFFF9FAFB); // gray-50
  static const white   = Colors.white;

  // Typography — tebal & bersih seperti di dashboard
  static const TextStyle h1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w900,
    color: ink, letterSpacing: -0.5, height: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w800,
    color: ink, letterSpacing: -0.3, height: 1.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w800,
    color: ink, letterSpacing: -0.2, height: 1.35,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13, color: muted, height: 1.55,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, color: soft, fontWeight: FontWeight.w500,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ARTICLE PAGE
// ══════════════════════════════════════════════════════════════════════════════
class ArticlePage extends StatefulWidget {
  final bool embedded;
  const ArticlePage({super.key, this.embedded = false});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getArticles();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.getArticles());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _T.surface,
        // ── AppBar — sama dengan gaya di dashboard ──
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          backgroundColor: _T.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: _T.border,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleSpacing: widget.embedded ? 16 : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon kotak — sama pola dengan ikon di appbar dashboard
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Colors.white, size: 17,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Artikel Kesehatan',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -0.3,
                  )),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _T.border),
          ),
        ),

        body: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _SkeletonList();
            }
            if (snap.hasError) {
              return _ErrorView(onRetry: _refresh);
            }
            final list = snap.data ?? [];
            if (list.isEmpty) return const _EmptyView();

            return RefreshIndicator(
              onRefresh: _refresh,
              color: _T.primary,
              strokeWidth: 2,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Banner hero — mirip banner "Cek Risiko Obesitas" di dashboard ──
                  SliverToBoxAdapter(
                    child: _HeroBanner(
                      item: list[0],
                      onTap: () => _push(ctx, list[0]),
                    ),
                  ),

                  // ── Section header "Artikel Lainnya" ──
                  if (list.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: _SectionHeader(label: 'Artikel Lainnya'),
                      ),
                    ),

                  // ── Daftar artikel — gaya card sama dengan "Layanan Kami" ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => _ServiceCard(
                          item: list[i + 1],
                          onTap: () => _push(c, list[i + 1]),
                        ),
                        childCount: list.length - 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _push(BuildContext ctx, dynamic item) {
    Navigator.push(ctx,
        MaterialPageRoute(builder: (_) => _DetailPage(article: item)));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HERO BANNER  — mirip banner "Cek Risiko Obesitas" di dashboard
//  tapi dengan gambar artikel sebagai latar
// ══════════════════════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _HeroBanner({required this.item, required this.onTap});

  String _img() {
    if (item['gambar'] != null && item['gambar'].toString().isNotEmpty)
      return ApiService.getImageUrl(item['gambar'].toString());
    return 'https://picsum.photos/seed/${item['_id'] ?? '1'}/800/400';
  }

  @override
  Widget build(BuildContext context) {
    final String? kat = item['kategori']?.toString();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        height: 200,
        decoration: BoxDecoration(
          color: _T.primary,
          borderRadius: BorderRadius.circular(20),
          // Sama persis shadow seperti banner dashboard
          boxShadow: [
            BoxShadow(
              color: _T.primary.withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Gambar artikel di sisi kanan (seperti ilustrasi dokter di dashboard)
          Positioned(
            right: 0, top: 0, bottom: 0,
            width: 150,
            child: Image.network(
              _img(), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _T.primaryL),
            ),
          ),
          // Gradient menutupi gambar agar teks terbaca
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _T.primary,
                    _T.primary,
                    _T.primary.withOpacity(0.85),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Konten teks di kiri
          Positioned(
            left: 0, top: 0, bottom: 0, right: 150,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Chip kategori — sama gaya dengan "KUIS KESEHATAN" di dashboard
                  if (kat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Text(kat.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8)),
                    ),
                  const SizedBox(height: 10),
                  // Judul — bold besar seperti "Cek Risiko Obesitas"
                  Text(
                    item['judul'] ?? 'Tanpa Judul',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tombol — sama persis dengan "Mulai Cek →" di dashboard
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Baca Artikel',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _T.primary)),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: _T.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SERVICE CARD  — sama persis dengan card "Cek BMI" & "SiObe Assistant"
//  di bagian "Layanan Kami" pada dashboard
// ══════════════════════════════════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _ServiceCard({required this.item, required this.onTap});

  String _img() {
    if (item['gambar'] != null && item['gambar'].toString().isNotEmpty)
      return ApiService.getImageUrl(item['gambar'].toString());
    return 'https://picsum.photos/seed/${item['_id'] ?? '1'}/200/200';
  }

  @override
  Widget build(BuildContext context) {
    final String? kat = item['kategori']?.toString();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(16),
          // Border tipis — sama persis dengan card layanan di dashboard
          border: Border.all(color: _T.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Thumbnail — sama ukuran & bentuk dengan ikon layanan di dashboard
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _T.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              _img(), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.article_rounded, color: _T.primary, size: 26),
            ),
          ),

          const SizedBox(width: 14),

          // Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul + chip kategori (sama pola dengan "Cek BMI GRATIS")
                Row(
                  children: [
                    Expanded(
                      child: Text(item['judul'] ?? 'Tanpa Judul',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _T.h3),
                    ),
                    if (kat != null) ...[
                      const SizedBox(width: 6),
                      _KatChip(label: kat),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Ringkasan — sama gaya dengan deskripsi layanan di dashboard
                Text(
                  item['ringkasan'] ?? item['isi'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.body,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          // Chevron kanan — sama persis dengan ">" di card layanan dashboard
          const Icon(Icons.chevron_right_rounded,
              color: _T.soft, size: 22),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION HEADER  — sama gaya "Layanan Kami" di dashboard
// ══════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800,
          color: _T.ink, letterSpacing: -0.2,
        ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  KATEGORI CHIP  — sama gaya "GRATIS" & "NEW" di dashboard
// ══════════════════════════════════════════════════════════════════════════════
class _KatChip extends StatelessWidget {
  final String label;
  const _KatChip({required this.label});

  Color get _bg {
    switch (label.toLowerCase()) {
      case 'gizi':      return const Color(0xFFFFF7ED);
      case 'olahraga':  return const Color(0xFFEFF6FF);
      case 'diet':      return const Color(0xFFFDF4FF);
      default:          return _T.primaryBg;
    }
  }

  Color get _fg {
    switch (label.toLowerCase()) {
      case 'gizi':      return const Color(0xFFC2410C);
      case 'olahraga':  return const Color(0xFF1D4ED8);
      case 'diet':      return const Color(0xFF7E22CE);
      default:          return _T.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _fg)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DETAIL PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _DetailPage extends StatelessWidget {
  final dynamic article;
  const _DetailPage({required this.article});

  String _img() {
    if (article['gambar'] != null &&
        article['gambar'].toString().isNotEmpty)
      return ApiService.getImageUrl(article['gambar'].toString());
    return 'https://picsum.photos/seed/${article['_id'] ?? '1'}/800/400';
  }

  @override
  Widget build(BuildContext context) {
    final String? kat = article['kategori']?.toString();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _T.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar dengan gambar — warna emerald seperti banner dashboard
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: _T.primary,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Image.network(_img(), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: _T.primaryL)),
                  // Gradient bawah — gelap untuk keterbacaan
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // Konten artikel
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip kategori
                        if (kat != null) _KatChip(label: kat),
                        const SizedBox(height: 12),

                        // Judul — bold seperti header di dashboard
                        Text(article['judul'] ?? '',
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: _T.ink, letterSpacing: -0.4,
                              height: 1.25,
                            )),

                        const SizedBox(height: 16),

                        // Meta penulis — card kecil seperti stat card di dashboard
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _T.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _T.border),
                          ),
                          child: Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: _T.primaryBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  size: 17, color: _T.primary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(article['penulis'] ?? 'Admin',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _T.ink,
                                    )),
                                const Text('Penulis',
                                    style: TextStyle(
                                        fontSize: 11, color: _T.soft)),
                              ],
                            ),
                          ]),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: _T.border, height: 1),
                        const SizedBox(height: 20),

                        // Isi artikel
                        Text(article['isi'] ?? '',
                            style: const TextStyle(
                              fontSize: 15, color: _T.inkSub,
                              height: 1.85, letterSpacing: 0.1,
                            )),

                        const SizedBox(height: 48),
                      ],
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

// ══════════════════════════════════════════════════════════════════════════════
//  SKELETON LOADING  — animasi placeholder saat fetch data
// ══════════════════════════════════════════════════════════════════════════════
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Color.lerp(
            const Color(0xFFE5E7EB), const Color(0xFFF3F4F6), _anim.value),
        borderRadius: BorderRadius.circular(r),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner skeleton
        _box(double.infinity, 200, r: 20),
        const SizedBox(height: 28),
        _box(120, 16, r: 4),
        const SizedBox(height: 14),
        // Card skeletons
        for (int i = 0; i < 4; i++) ...[
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: _T.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              _box(50, 50, r: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _box(double.infinity, 12, r: 4),
                    const SizedBox(height: 8),
                    _box(180, 10, r: 4),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ERROR & EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: Color(0xFFEF4444), size: 30),
          ),
          const SizedBox(height: 16),
          const Text('Gagal memuat',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _T.ink)),
          const SizedBox(height: 6),
          const Text('Periksa koneksi internet kamu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _T.muted)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _T.primaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.article_rounded,
              color: _T.primary, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('Belum ada artikel',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _T.ink)),
        const SizedBox(height: 6),
        const Text('Artikel akan segera ditambahkan.',
            style: TextStyle(fontSize: 13, color: _T.muted)),
      ]),
    );
  }
}