import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/mikrotik_api_service.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/app_colors.dart';

class WdcpControlPage extends StatefulWidget {
  final String ip;
  final String storeName;
  final String storeCode;

  const WdcpControlPage({
    super.key,
    required this.ip,
    required this.storeName,
    required this.storeCode,
  });

  @override
  State<WdcpControlPage> createState() => _WdcpControlPageState();
}

class _WdcpControlPageState extends State<WdcpControlPage>
    with SingleTickerProviderStateMixin {
  // Koneksi dikelola per-isolate — tidak ada persistent socket di main thread

  String _winboxUser = '';
  String _winboxPass = '';
  int _apiPort = 8728;
  String _winboxPort = '8291';

  bool _isLoading = true;
  bool _isConnected = false;
  bool _isRefreshingList = false;
  bool _animationsReady = false;

  List<Map<String, String>> _connectedDevices = [];
  List<Map<String, String>> _accessList = [];
  List<Map<String, String>> _filteredAccessList = [];
  Map<String, String> _systemInfo = {};
  bool _defaultAuthStatus = false;

  late TabController _tabController;
  final _macController = TextEditingController();
  final _commentController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    _loadSettingsAndConnect();
  }

  @override
  void dispose() {
    _macController.dispose();
    _commentController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndConnect() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select();
      final data = {for (var item in response) item['key']: item['value']};
      setState(() {
        _winboxUser = data['wdcp_user'] ?? 'admin';
        _winboxPass = data['wdcp_pass'] ?? '';
        _apiPort = int.tryParse(data['api_port'] ?? '8728') ?? 8728;
        _winboxPort = data['winbox_port'] ?? '8291';
      });
      await _connectAndLoad();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          "Gagal ambil konfigurasi WDCP: $e",
          context.dangerColor,
        );
      }
    }
  }

  Future<void> _connectAndLoad() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isConnected = false;
    });

    final result = await _connectAndFetch();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _connectedDevices = List<Map<String, String>>.from(
          result['devices'] ?? [],
        );
        _accessList = List<Map<String, String>>.from(
          result['accessList'] ?? [],
        );
        _filteredAccessList = _accessList;
        _defaultAuthStatus = result['authStatus'] as bool? ?? false;
        _systemInfo = Map<String, String>.from(result['sysInfo'] ?? {});
        _isConnected = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      CustomSnackBar.show(
        context,
        "Gagal Konek: ${result['error']}",
        context.dangerColor,
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isRefreshingList = true);

    final result = await _connectAndFetch();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _connectedDevices = List<Map<String, String>>.from(
          result['devices'] ?? [],
        );
        _accessList = List<Map<String, String>>.from(
          result['accessList'] ?? [],
        );
        _filterAccessList(_searchController.text);
        _defaultAuthStatus = result['authStatus'] as bool? ?? false;
        _systemInfo = Map<String, String>.from(result['sysInfo'] ?? {});
      });
    }

    if (mounted) setState(() => _isRefreshingList = false);
  }

  void _filterAccessList(String query) {
    if (query.isEmpty) {
      setState(() => _filteredAccessList = _accessList);
    } else {
      setState(() {
        _filteredAccessList = _accessList.where((item) {
          final mac = (item['mac-address'] ?? '').toLowerCase();
          final comment = (item['comment'] ?? '').toLowerCase();
          final q = query.toLowerCase();
          return mac.contains(q) || comment.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _addMac() async {
    FocusScope.of(context).unfocus();
    final macInput = _macController.text.trim();
    final commentInput = _commentController.text.trim();

    if (macInput.isEmpty) {
      CustomSnackBar.show(
        context,
        "MAC Address tidak boleh kosong",
        context.dangerColor,
      );
      return;
    }
    bool isDuplicate = _accessList.any(
      (item) => item['mac-address'] == macInput,
    );
    if (isDuplicate) {
      CustomSnackBar.show(
        context,
        "GAGAL: MAC $macInput sudah terdaftar!",
        context.dangerColor,
      );
      return;
    }
    final result = await _doAddMac(macInput, commentInput);

    if (!mounted) return;

    if (result['success'] == true) {
      CustomSnackBar.show(
        context,
        "Sukses menambahkan $macInput",
        context.successColor,
      );
      _macController.clear();
      _commentController.clear();
      _refreshData();
      _tabController.animateTo(1);
    } else {
      CustomSnackBar.show(
        context,
        "Gagal tambah: ${result['error']}",
        context.dangerColor,
      );
    }
  }

  Future<void> _removeMac(String id, String mac) async {
    final result = await _doRemoveMac(id);

    if (!mounted) return;

    if (result['success'] == true) {
      CustomSnackBar.show(
        context,
        "MAC $mac berhasil dihapus",
        const Color(0xFFFFB347),
      );
      _refreshData();
    } else {
      CustomSnackBar.show(
        context,
        "Gagal hapus: ${result['error']}",
        context.dangerColor,
      );
    }
  }

  Future<void> _toggleAuth(bool value) async {
    final result = await _doToggleAuth(value);

    if (!mounted) return;

    if (result['success'] == true) {
      CustomSnackBar.show(
        context,
        "Default Authenticate: ${value ? 'ENABLED' : 'DISABLED'}",
        value ? context.dangerColor : context.successColor,
      );
      _refreshData();
    } else {
      CustomSnackBar.show(
        context,
        "Gagal ubah setting: ${result['error']}",
        context.dangerColor,
      );
    }
  }

  // ── ROUTER OPERATIONS (async/await langsung — tanpa isolate overhead) ───────

  /// Koneksi + ambil semua data sekaligus
  Future<Map<String, dynamic>> _connectAndFetch() async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(widget.ip, _apiPort, _winboxUser, _winboxPass);

      List<Map<String, String>> devices = [];
      List<Map<String, String>> accessList = [];
      bool authStatus = false;
      Map<String, String> sysInfo = {};

      try {
        devices = await svc.getRegistrationTable();
      } catch (_) {}
      try {
        accessList = await svc.getAccessList();
      } catch (_) {}
      try {
        authStatus = await svc.getDefaultAuthStatus();
      } catch (_) {}
      try {
        sysInfo = await svc.getSystemResource();
      } catch (_) {}

      return {
        'success': true,
        'devices': devices,
        'accessList': accessList,
        'authStatus': authStatus,
        'sysInfo': sysInfo,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      svc.disconnect();
    }
  }

  /// Tambah MAC ke access list
  Future<Map<String, dynamic>> _doAddMac(String mac, String comment) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(widget.ip, _apiPort, _winboxUser, _winboxPass);
      await svc.addAccessList(mac, comment);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      svc.disconnect();
    }
  }

  /// Hapus MAC dari access list
  Future<Map<String, dynamic>> _doRemoveMac(String id) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(widget.ip, _apiPort, _winboxUser, _winboxPass);
      await svc.removeAccessList(id);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      svc.disconnect();
    }
  }

  /// Toggle default authenticate
  Future<Map<String, dynamic>> _doToggleAuth(bool value) async {
    final svc = MikrotikApiService();
    try {
      await svc.connect(widget.ip, _apiPort, _winboxUser, _winboxPass);
      await svc.setDefaultAuth(value);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      svc.disconnect();
    }
  }

  Future<void> _launchWinbox() async {
    const winboxPath = r'D:\Edp NetOps\winbox.exe';
    if (!await File(winboxPath).exists()) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "File winbox.exe tidak ditemukan!",
          context.dangerColor,
        );
      }
      return;
    }
    try {
      final address = '${widget.ip}:$_winboxPort';
      await Process.start(winboxPath, [
        address,
        _winboxUser,
        _winboxPass,
      ], mode: ProcessStartMode.detached);
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Membuka Winbox ke $address...",
          context.accentColor,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Error Winbox: $e", context.dangerColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: _isLoading
          ? _buildLoadingState()
          : AnimatedOpacity(
              opacity: _animationsReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: !_isConnected
                          ? _buildErrorView()
                          : Column(
                              children: [
                                _buildStatusHeader(),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (_, constraints) {
                                    final isWide = constraints.maxWidth >= 700;
                                    final rightPanels = Column(
                                      children: [
                                        _buildSecurityPanel(),
                                        const SizedBox(height: 16),
                                        _buildAddMacPanel(),
                                        const SizedBox(height: 16),
                                        _buildRouterInfoPanel(),
                                      ],
                                    );
                                    if (isWide) {
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: _buildLeftTabPanel(),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(flex: 4, child: rightPanels),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          _buildLeftTabPanel(compact: true),
                                          const SizedBox(height: 16),
                                          rightPanels,
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "MENGHUBUNGKAN KE RBWDCP...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.ip,
              style: TextStyle(
                color: context.accentColor,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isConnected ? context.successColor : context.dangerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isConnected
                              ? context.successColor
                              : context.dangerColor)
                          .withOpacity(0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RB WDCP — ${widget.storeCode}",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                widget.storeName,
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isConnected ? _connectAndLoad : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.accentColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: context.accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Reconnect",
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
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

  // ==========================================
  // STATUS HEADER
  // ==========================================
  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.successColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: context.successColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 360;

          final iconAndStatus = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.successColor.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.router_outlined,
                  color: context.successColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STATUS RBWDCP",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "ONLINE",
                        style: TextStyle(
                          color: context.successColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.successColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.successColor.withOpacity(0.7),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final ipBox = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: isWide
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  "IP RBWDCP",
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ip,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(children: [iconAndStatus, const Spacer(), ipBox]);
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconAndStatus,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ipBox),
              ],
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // LEFT TAB PANEL
  // ==========================================
  Widget _buildLeftTabPanel({bool compact = false}) {
    // compact = true di layar sempit → tinggi adaptif (tidak fixed)
    return Container(
      height: compact ? 500 : 600,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // TAB HEADER
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: context.accentColor,
              unselectedLabelColor: context.textSecondary,
              indicatorColor: context.accentColor,
              indicatorWeight: 2,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.smartphone_outlined, size: 15),
                      const SizedBox(width: 6),
                      Text("ONLINE (${_connectedDevices.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt_outlined, size: 15),
                      const SizedBox(width: 6),
                      Text("WHITELIST (${_accessList.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: ONLINE DEVICES
                _buildListContent(
                  data: _connectedDevices,
                  isAccessList: false,
                  emptyIcon: Icons.wifi_find_outlined,
                  emptyText: "Tidak ada perangkat terhubung",
                ),
                // TAB 2: WHITELIST
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: TextSelectionThemeData(
                            cursorColor: context.accentColor,
                            selectionColor: context.accentColor.withOpacity(
                              0.3,
                            ),
                            selectionHandleColor: context.accentColor,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterAccessList,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                          ),
                          cursorColor: context.accentColor,
                          decoration: InputDecoration(
                            hintText: "Cari MAC Address atau Nama...",
                            hintStyle: TextStyle(
                              color: context.textSecondary.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 16,
                              color: context.textSecondary,
                            ),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: context.surfaceColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: context.accentColor,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 14,
                                      color: context.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterAccessList('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildListContent(
                        data: _filteredAccessList,
                        isAccessList: true,
                        emptyIcon: Icons.search_off_outlined,
                        emptyText: _searchController.text.isEmpty
                            ? "Access List kosong"
                            : "Tidak ditemukan",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FOOTER
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isRefreshingList ? null : _refreshData,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isRefreshingList
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: context.accentColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: context.accentColor,
                            ),
                      const SizedBox(width: 6),
                      Text(
                        _isRefreshingList ? "Memuat..." : "Refresh Data",
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  Widget _buildListContent({
    required List<Map<String, String>> data,
    required bool isAccessList,
    required IconData emptyIcon,
    required String emptyText,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(emptyIcon, size: 28, color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final Color itemAccent = isAccessList
        ? const Color(0xFFFFB347)
        : context.successColor;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: data.length,
      separatorBuilder: (c, i) => Divider(
        height: 1,
        color: context.borderColor.withOpacity(0.5),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = data[index];
        final mac = item['mac-address'] ?? item['mac'] ?? '-';
        final comment = item['comment'] ?? '-';
        final uptime = item['uptime'] ?? '';
        final id = item['.id'];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: mac));
              CustomSnackBar.show(
                context,
                "MAC Address disalin!",
                context.accentColor,
              );
            },
            splashColor: context.accentColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: itemAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: itemAccent.withOpacity(0.25)),
                    ),
                    child: Icon(
                      isAccessList
                          ? Icons.vpn_key_outlined
                          : Icons.smartphone_outlined,
                      color: itemAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mac,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAccessList
                              ? (comment != '-' ? comment : "No Comment")
                              : "Uptime: $uptime",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAccessList && comment != '-' && comment.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: context.accentColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        comment,
                        style: TextStyle(
                          fontSize: 9,
                          color: context.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isAccessList && id != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDeleteMacDialog(id, mac),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.dangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.dangerColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: context.dangerColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteMacDialog(String id, String mac) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1520),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.dangerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: context.dangerColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Hapus Akses?",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hapus MAC Address berikut dari Whitelist?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        mac,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _removeMac(id, mac);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.dangerColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Hapus",
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
        ),
      ),
    );
  }

  // ==========================================
  // RIGHT PANELS
  // ==========================================
  Widget _buildSecurityPanel() {
    final isEnabled = _defaultAuthStatus;
    final Color statusColor = isEnabled
        ? context.dangerColor
        : context.successColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            "DEFAULT AUTHENTICATE",
            Icons.security_outlined,
            statusColor,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isEnabled ? "ENABLED" : "DISABLED",
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isEnabled,
                  onChanged: _toggleAuth,
                  activeThumbColor: context.dangerColor,
                  inactiveThumbColor: context.successColor,
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return context.dangerColor.withOpacity(0.25);
                    }
                    return context.successColor.withOpacity(0.2);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEnabled
                ? "⚠ Semua perangkat dapat terhubung"
                : "✓ Hanya perangkat whitelist",
            style: TextStyle(color: context.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMacPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            "TAMBAH MAC ADDRESS",
            Icons.add_moderator_outlined,
            const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 16),
          _buildDarkTextField(
            controller: _macController,
            label: "MAC Address",
            hint: "AA:BB:CC:DD:EE:FF",
            icon: Icons.lan_outlined,
            isMonospace: true,
          ),
          const SizedBox(height: 10),
          _buildDarkTextField(
            controller: _commentController,
            label: "Comment / Nama Perangkat",
            hint: "Toko / IC / Keterangan lain",
            icon: Icons.label_outline,
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _addMac,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Tambah Mac Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouterInfoPanel() {
    String boardName = _systemInfo['board-name'] ?? '-';
    String version = _systemInfo['version'] ?? '-';
    String cpuLoad = _systemInfo['cpu-load'] ?? '0';
    String freeMem = _systemInfo['free-memory'] ?? '0';
    String uptime = _systemInfo['uptime'] ?? '-';

    try {
      double memMb = double.parse(freeMem) / 1024 / 1024;
      freeMem = "${memMb.toStringAsFixed(1)} MB";
    } catch (_) {}

    final int cpuInt = int.tryParse(cpuLoad) ?? 0;
    final Color cpuColor = cpuInt > 80
        ? context.dangerColor
        : cpuInt > 50
        ? const Color(0xFFFFB347)
        : context.successColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            "ROUTER INFO",
            Icons.monitor_heart_outlined,
            const Color(0xFF00C9A7),
          ),
          const SizedBox(height: 14),

          // CPU Load Bar
          Row(
            children: [
              Text(
                "CPU",
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cpuInt / 100,
                    backgroundColor: context.surfaceColor,
                    valueColor: AlwaysStoppedAnimation<Color>(cpuColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$cpuLoad%",
                style: TextStyle(
                  color: cpuColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info Grid
          Row(
            children: [
              Expanded(child: _buildInfoTile("Board", boardName)),
              Expanded(child: _buildInfoTile("RouterOS", "v$version")),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInfoTile("Free RAM", freeMem)),
              Expanded(child: _buildInfoTile("Uptime", uptime)),
            ],
          ),
          const SizedBox(height: 16),

          // Winbox Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _launchWinbox,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.window_outlined,
                      color: context.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Buka Winbox",
                      style: TextStyle(
                        color: context.accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildPanelHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isMonospace = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),

        // --- BUNGKUS TEXTFIELD DENGAN THEME ---
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: context.accentColor, // Warna kursor kelap-kelip
              selectionColor: context.accentColor.withOpacity(
                0.3,
              ), // Warna blok teks
              selectionHandleColor:
                  context.accentColor, // Warna pentolan kursor di HP
            ),
          ),
          child: TextField(
            controller: controller,
            cursorColor: context.accentColor, // Penegasan warna kursor
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontFamily: isMonospace ? 'monospace' : null,
              letterSpacing: isMonospace ? 0.5 : 0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.textSecondary.withOpacity(0.4),
                fontSize: 12,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 15, color: context.textSecondary)
                  : null,
              filled: true,
              fillColor: context.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: context.accentColor, width: 1.5),
              ),
            ),
          ),
        ),

        // --------------------------------------
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.dangerColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: context.dangerColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Gagal Terhubung",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tidak dapat konek ke Router WDCP\n${widget.ip}",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _connectAndLoad,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: context.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Coba Lagi",
                      style: TextStyle(
                        color: context.accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
