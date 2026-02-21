import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/encryption_helper.dart';
import '../../utils/custom_snackbar.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../store_management/store_list_page.dart';
import '../../utils/app_colors.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  bool _animationsReady = false;

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _obsOld = true;
  bool _obsNew = true;

  // Variabel untuk Daftar User & Pencarian
  List<dynamic> _userList = [];
  List<dynamic> _filteredUserList = [];
  bool _isLoadingUsers = true;
  final TextEditingController _searchUserCtrl = TextEditingController();
  final ScrollController _userListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    _fetchUsers();
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _searchUserCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI: AMBIL DAFTAR PENGGUNA DARI SUPABASE
  // ==========================================
  Future<void> _fetchUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('role', ascending: true);

      if (mounted) {
        setState(() {
          _userList = data;
          _filteredUserList = data; // Awalnya tampilkan semua
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil data user: $e");
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  // ==========================================
  // FUNGSI: PENCARIAN USER (SEARCH)
  // ==========================================
  void _filterUsers(String keyword) {
    if (keyword.isEmpty) {
      setState(() => _filteredUserList = _userList);
    } else {
      setState(() {
        _filteredUserList = _userList.where((user) {
          final nama = (user['nama'] ?? '').toString().toLowerCase();
          final nik = (user['nik'] ?? '').toString().toLowerCase();
          final searchLower = keyword.toLowerCase();
          return nama.contains(searchLower) || nik.contains(searchLower);
        }).toList();
      });
    }
  }

  // ==========================================
  // FUNGSI: BERSIHKAN CACHE APLIKASI
  // ==========================================
  Future<void> _clearAppCache() async {
    setState(() => _isLoading = true);
    try {
      // Membersihkan cache gambar dari memori (sangat berguna untuk aplikasi dengan banyak UI)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Simulasi loading agar user merasa ada proses pembersihan yang terjadi
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        CustomSnackBar.show(
          context,
          "Cache & Memori sistem berhasil dibersihkan! Aplikasi lebih ringan.",
          const Color(0xFF00C9A7), // Warna hijau neon
        );
      }
    } catch (e) {
      if (mounted)
        CustomSnackBar.show(
          context,
          "Gagal membersihkan cache: $e",
          Colors.red,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // FUNGSI: HAPUS USER (HANYA ADMINISTRATOR)
  // ==========================================
  Future<void> _deleteUser(String nik, String nama) async {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_remove_outlined,
                        color: Color(0xFFFF6B6B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Hapus Pengguna?",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Apakah Anda yakin ingin menghapus $nama (NIK: $nik) dari sistem? Tindakan ini tidak dapat dibatalkan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext); // Tutup dialog dulu
                              setState(() => _isLoadingUsers = true);
                              try {
                                await Supabase.instance.client
                                    .from('profiles')
                                    .delete()
                                    .eq('nik', nik);

                                if (mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    "Pengguna berhasil dihapus!",
                                    Colors.green,
                                  );
                                  _fetchUsers(); // Refresh data setelah hapus
                                }
                              } catch (e) {
                                if (mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    "Gagal menghapus: $e",
                                    Colors.red,
                                  );
                                  setState(() => _isLoadingUsers = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Ya, Hapus",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // FUNGSI: UBAH PASSWORD PRIBADI
  // ==========================================
  Future<void> _updateMyPassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      CustomSnackBar.show(
        context,
        "Password lama & baru harus diisi!",
        Colors.red,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final oldHash = EncryptionHelper.hashPassword(_oldPassCtrl.text);
      final newHash = EncryptionHelper.hashPassword(_newPassCtrl.text);
      final check = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('nik', currentUserNik)
          .eq('password', oldHash)
          .maybeSingle();
      if (check == null) {
        if (mounted)
          CustomSnackBar.show(context, "Password lama salah!", Colors.red);
        return;
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'password': newHash})
          .eq('nik', currentUserNik);
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Password berhasil diperbarui!",
          Colors.green,
        );
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, "Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingOverlay()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _animationsReady ? Offset.zero : const Offset(0, 0.04),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Column(
                          children: [
                            _buildProfileHeroCard(),
                            const SizedBox(height: 24),

                            _buildSectionHeader(
                              "KEAMANAN AKUN",
                              Icons.shield_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildSecurityCard(),
                            const SizedBox(height: 24),

                            _buildSectionHeader(
                              "DAFTAR TIM EDP",
                              Icons.group_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildUserListCard(),

                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              "TENTANG APLIKASI",
                              Icons.info_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildSystemInfoCard(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // DAFTAR TIM EDP CARD — Modern & Professional
  // ==========================================
  Widget _buildUserListCard() {
    final isAdministrator = currentUserRole.toLowerCase() == 'administrator';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER — Responsif ──
          LayoutBuilder(
            builder: (_, constraints) {
              // 💡 PERBAIKAN 1: Batas layar dinaikkan jadi 600 agar lebih responsif
              final isWide = constraints.maxWidth >= 600;

              // titleWidget: icon + judul + subtitle
              final titleWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00C9A7).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.group_outlined,
                      color: Color(0xFF00C9A7),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 💡 PERBAIKAN 2: Bungkus Column teks dengan Expanded
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Personil Terdaftar",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Agar teks jadi titik-titik jika kepanjangan
                        ),
                        Text(
                          "Pengguna yang memiliki akses sistem",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              // badgeWidget: jumlah personil
              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C9A7).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  "${_filteredUserList.length} Orang",
                  style: const TextStyle(
                    color: Color(0xFF00C9A7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              // searchWidget: fixed 190px di desktop, full-width di mobile
              final searchWidget = SizedBox(
                width: isWide ? 190 : double.infinity,
                height: 36,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: context.accentColor,
                      selectionColor: context.accentColor.withOpacity(0.3),
                      selectionHandleColor: context.accentColor,
                    ),
                  ),
                  child: TextField(
                    controller: _searchUserCtrl,
                    onChanged: _filterUsers,
                    cursorColor: context.accentColor,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau NIK...",
                      hintStyle: TextStyle(
                        color: context.textSecondary.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.textSecondary,
                        size: 18,
                      ),
                      suffixIcon: _searchUserCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: context.textSecondary,
                                size: 16,
                              ),
                              onPressed: () {
                                _searchUserCtrl.clear();
                                _filterUsers('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.accentColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              );

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(color: context.borderColor),
                  ),
                ),
                child: isWide
                    // DESKTOP: [Expanded(judul)] [search] [badge]
                    ? Row(
                        children: [
                          Expanded(child: titleWidget),
                          searchWidget,
                          const SizedBox(width: 10),
                          badgeWidget,
                        ],
                      )
                    // MOBILE / LAYAR KECIL: judul+badge baris 1, search baris 2
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: titleWidget),
                              badgeWidget,
                            ],
                          ),
                          const SizedBox(height: 12),
                          searchWidget, // Search bar otomatis pindah ke bawah di sini!
                        ],
                      ),
              );
            },
          ),

          // ── LIST AREA ─────────────────────────────────────────
          if (_isLoadingUsers)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: context.accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Memuat data tim...",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredUserList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      color: context.textSecondary.withOpacity(0.4),
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tidak ada personil ditemukan.",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: RawScrollbar(
                controller: _userListScrollController,
                thumbColor: context.accentColor.withOpacity(0.4),
                radius: const Radius.circular(4),
                thickness: 4,
                child: ListView.builder(
                  controller: _userListScrollController,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  itemCount: _filteredUserList.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUserList[index];
                    final role = (user['role'] ?? 'User')
                        .toString()
                        .toUpperCase();
                    final nama = user['nama'] ?? 'Unknown';
                    final nik = user['nik'] ?? '-';
                    final isMe = nik == currentUserNik;
                    final isLast = index == _filteredUserList.length - 1;

                    Color roleColor;
                    IconData roleIcon;
                    if (role == 'ADMINISTRATOR') {
                      roleColor = const Color(0xFFFF6B6B);
                      roleIcon = Icons.shield_outlined;
                    } else if (role == 'ADMIN') {
                      roleColor = const Color(0xFFFFB347);
                      roleIcon = Icons.manage_accounts_outlined;
                    } else {
                      roleColor = context.accentColor;
                      roleIcon = Icons.person_outline;
                    }

                    // Inisial avatar (maks 2 huruf)
                    final initials = nama.trim().split(' ').length >= 2
                        ? '${nama.trim().split(' ')[0][0]}${nama.trim().split(' ')[1][0]}'
                              .toUpperCase()
                        : nama.isNotEmpty
                        ? nama[0].toUpperCase()
                        : 'U';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // ── Avatar ──────────────────────────
                              Stack(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: roleColor.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          color: roleColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: context.cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: context.borderColor,
                                        ),
                                      ),
                                      child: Icon(
                                        roleIcon,
                                        size: 10,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // ── Info ────────────────────────────
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            nama,
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.accentColor
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: context.accentColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              "ANDA",
                                              style: TextStyle(
                                                color: context.accentColor,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.badge_outlined,
                                          size: 11,
                                          color: context.textSecondary
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          nik,
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ── Role Badge + Delete ──────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: roleColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  if (isAdministrator && !isMe) ...[
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => _deleteUser(nik, nama),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFF6B6B,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFFF6B6B,
                                            ).withOpacity(0.25),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFFF6B6B),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: context.borderColor.withOpacity(0.5),
                            indent: 72,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET LAINNYA
  // ==========================================
  Widget _buildLoadingOverlay() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Memproses...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "PROFIL SAYA",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard() {
    Color roleAccent;
    Color roleBg;
    IconData roleIcon;
    String roleLabel;
    switch (currentUserRole.toLowerCase()) {
      case 'administrator':
        roleAccent = const Color(0xFFFF6B6B);
        roleBg = const Color(0xFF2A1520);
        roleIcon = Icons.admin_panel_settings_outlined;
        roleLabel = 'ADMINISTRATOR';
        break;
      case 'admin':
        roleAccent = const Color(0xFFFFB347);
        roleBg = const Color(0xFF241D10);
        roleIcon = Icons.manage_accounts_outlined;
        roleLabel = 'ADMIN';
        break;
      default:
        roleAccent = context.accentColor;
        roleBg = const Color(0xFF0A2030);
        roleIcon = Icons.person_outline;
        roleLabel = 'USER';
    }

    // Inisial avatar (maks 2 huruf)
    final nameParts = currentUserName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    final isDark = themeNotifier.value == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: roleAccent.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── ATAS: gradient banner + avatar ───────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleAccent.withOpacity(0.13),
                  context.accentColor.withOpacity(0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth >= 600;

                // ── Avatar ──────────────────────────────────────
                final avatar = Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleAccent, roleAccent.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: roleAccent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    // Role icon badge di sudut kanan bawah
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: roleAccent.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(roleIcon, size: 14, color: roleAccent),
                      ),
                    ),
                  ],
                );

                // ── Info teks ────────────────────────────────────
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUserName,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 11, color: roleAccent),
                          const SizedBox(width: 5),
                          Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // NIK row
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'NIK  ',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentUserNik,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                return isWide
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            avatar,
                            const SizedBox(width: 20),
                            Expanded(child: info),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [avatar, const SizedBox(height: 16), info],
                        ),
                      );
              },
            ),
          ),

          // ── BAWAH: quick actions ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth >= 420;

                // Toggle dark/light
                final themeToggle = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: context.accentColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDark ? 'Mode Gelap' : 'Mode Terang',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isDark,
                        activeThumbColor: context.accentColor,
                        activeTrackColor: context.accentColor.withOpacity(0.25),
                        onChanged: (val) => setState(() {
                          themeNotifier.value = val
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        }),
                      ),
                    ),
                  ],
                );

                // Tombol clear cache
                final cacheBtn = InkWell(
                  onTap: _clearAppCache,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFB347).withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cleaning_services_outlined,
                          size: 14,
                          color: Color(0xFFFFB347),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Clear Cache',
                          style: TextStyle(
                            color: Color(0xFFFFB347),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                return isWide
                    // Lebar: toggle kiri, cache button kanan
                    ? Row(children: [themeToggle, const Spacer(), cacheBtn])
                    // Sempit: toggle atas, cache button bawah full-width
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          themeToggle,
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: _clearAppCache,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB347,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFB347,
                                    ).withOpacity(0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cleaning_services_outlined,
                                      size: 14,
                                      color: Color(0xFFFFB347),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Bersihkan Cache Sistem',
                                      style: TextStyle(
                                        color: Color(0xFFFFB347),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Ubah Password",
            "Perbarui password login Anda secara berkala.",
            Icons.lock_outline,
            context.accentColor,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 480;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        "Password Lama",
                        _oldPassCtrl,
                        prefixIcon: Icons.lock_outline,
                        isPass: true,
                        isObs: _obsOld,
                        onObsToggle: () => setState(() => _obsOld = !_obsOld),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildModernTextField(
                        "Password Baru",
                        _newPassCtrl,
                        prefixIcon: Icons.lock_reset_outlined,
                        isPass: true,
                        isObs: _obsNew,
                        onObsToggle: () => setState(() => _obsNew = !_obsNew),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildModernTextField(
                      "Password Lama",
                      _oldPassCtrl,
                      prefixIcon: Icons.lock_outline,
                      isPass: true,
                      isObs: _obsOld,
                      onObsToggle: () => setState(() => _obsOld = !_obsOld),
                    ),
                    const SizedBox(height: 14),
                    _buildModernTextField(
                      "Password Baru",
                      _newPassCtrl,
                      prefixIcon: Icons.lock_reset_outlined,
                      isPass: true,
                      isObs: _obsNew,
                      onObsToggle: () => setState(() => _obsNew = !_obsNew),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _updateMyPassword,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.accentColor,
                        context.accentColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Ubah Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI SISTEM & CLEAR CACHE
  // ==========================================
  Widget _buildSystemInfoCard() {
    final infoItems = [
      (Icons.apps_rounded, 'Nama Aplikasi', 'EDP NetOps', context.accentColor),
      (
        Icons.tag_rounded,
        'Versi',
        'v2.0 (Enterprise Build)',
        context.accentColor,
      ),
      (Icons.build_circle_outlined, 'Build', '2026.02', context.textSecondary),
      (
        Icons.storage_outlined,
        'Database',
        'Supabase PostgreSQL',
        const Color(0xFF3ECF8E),
      ),
      (
        Icons.devices_outlined,
        'Platform',
        'Flutter (Cross-Platform)',
        const Color(0xFF54C5F8),
      ),
      (
        Icons.palette_outlined,
        'UI Framework',
        'Material Design 3',
        const Color(0xFFFFB347),
      ),
      (Icons.person_outline, 'Developer', 'Pahruroji', const Color(0xFFBB86FC)),

      (
        Icons.copyright_outlined,
        'Hak Cipta',
        '© 2026  All Rights Reserved.',
        context.textSecondary,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── TOP BANNER ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor.withOpacity(0.15),
                  context.secondaryAccent.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lan_outlined,
                    size: 26,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'EDP',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: ' NetOps',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Network Operations Center',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'v2.0.1',
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── STATUS PILLS ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                _buildStatusPill(
                  Icons.cloud_done_outlined,
                  'Connected',
                  const Color(0xFF00E676),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  Icons.security_outlined,
                  'Encrypted',
                  context.accentColor,
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  Icons.verified_outlined,
                  'Stable',
                  const Color(0xFFFFB347),
                ),
              ],
            ),
          ),

          // ── INFO ROWS ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: List.generate(infoItems.length, (i) {
                final item = infoItems[i];
                final icon = item.$1;
                final label = item.$2;
                final value = item.$3;
                final color = item.$4;
                final isLast = i == infoItems.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(icon, size: 15, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              softWrap: true,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: context.borderColor.withOpacity(0.5),
                        indent: 44,
                      ),
                  ],
                );
              }),
            ),
          ),

          // ── FOOTER ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'System Online  ·  © 2026 Developed by Pahruroji',
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: status pill
  Widget _buildStatusPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController ctrl, {
    IconData? prefixIcon,
    bool isPass = false,
    bool isObs = false,
    VoidCallback? onObsToggle,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: context.accentColor,
          selectionColor: context.accentColor.withOpacity(0.3),
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: isPass ? isObs : false,
        cursorColor: context.accentColor,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: context.textSecondary, size: 18)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
          filled: true,
          fillColor: context.cardColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          suffixIcon: isPass && onObsToggle != null
              ? IconButton(
                  icon: Icon(
                    isObs
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  onPressed: onObsToggle,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    // Warna & icon sesuai role
    Color roleAccentD;
    IconData roleIconD;
    switch (currentUserRole.toLowerCase()) {
      case 'administrator':
        roleAccentD = const Color(0xFFFF6B6B);
        roleIconD = Icons.admin_panel_settings_outlined;
        break;
      case 'admin':
        roleAccentD = const Color(0xFFFFB347);
        roleIconD = Icons.manage_accounts_outlined;
        break;
      default:
        roleAccentD = context.accentColor;
        roleIconD = Icons.person_outline;
    }

    // Inisial 2 huruf
    final nameParts = currentUserName.trim().split(' ');
    final initialsD = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : currentUserName.isNotEmpty
        ? currentUserName[0].toUpperCase()
        : 'U';

    return Drawer(
      backgroundColor: context.surfaceColor,
      child: Column(
        children: [
          // ── HEADER DRAWER ─────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleAccentD.withOpacity(0.13), context.cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + status online
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar kotak inisial 2 huruf
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roleAccentD,
                                    roleAccentD.withOpacity(0.55),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleAccentD.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initialsD,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Role icon badge sudut kanan bawah
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: roleAccentD.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  roleIconD,
                                  size: 12,
                                  color: roleAccentD,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Status pill online
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00E676).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withOpacity(0.7),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Nama
                    Text(
                      currentUserName.isNotEmpty ? currentUserName : 'User',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 5),

                    // NIK monospace
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: context.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          currentUserNik,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleAccentD.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: roleAccentD.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIconD, size: 11, color: roleAccentD),
                          const SizedBox(width: 6),
                          Text(
                            currentUserRole.toUpperCase(),
                            style: TextStyle(
                              color: roleAccentD,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const DashboardPage()),
              );
            },
          ),
          _buildDrawerTile(
            icon: Icons.store_outlined,
            label: 'Data Toko',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const StoreListPage()),
              );
            },
          ),
          if (currentUserRole.toLowerCase() == 'administrator') ...[
            // Menu Setting hanya akan dirender/digambar jika rolenya administrator
            _buildDrawerTile(
              icon: Icons.settings_outlined,
              label: 'Setting',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const SettingsPage()),
                );
              },
            ),
          ],
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(
                Icons.person_outline,
                color: context.accentColor,
                size: 20,
              ),
              title: Text(
                'Profil Saya',
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 1,
            color: context.borderColor,
          ),
          const SizedBox(height: 8),
          _buildDrawerTile(
            icon: Icons.logout_outlined,
            label: 'Keluar Aplikasi',
            iconColor: const Color(0xFFFF6B6B),
            labelColor: const Color(0xFFFF6B6B),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor ?? context.textSecondary, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Color(0xFFFF6B6B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Keluar Aplikasi?",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Apakah Anda yakin ingin keluar dari aplikasi EDP NetOps?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              currentUserNik = '';
                              currentUserName = '';
                              currentUserRole = '';
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Ya, Keluar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
