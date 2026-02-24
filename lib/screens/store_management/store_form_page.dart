import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/store_model.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/app_colors.dart';
import '../../utils/activity_logger.dart';

class StoreFormPage extends StatefulWidget {
  final StoreModel? store;
  const StoreFormPage({super.key, this.store});

  @override
  State<StoreFormPage> createState() => _StoreFormPageState();
}

class _StoreFormPageState extends State<StoreFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _animationsReady = false;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedConnection;
  String? _selectedBackup;

  final List<String> _connectionTypes = [
    'FO-Astinet',
    'FO-Astinet SDWAN',
    'FO-Icon',
    'FO-Icon SDWAN',
    'FO-Fiberstar SDWAN',
    'FO-Other',
    'OVPN-GSM Orbit',
    'OVPN-XL HO',
    'Vsat-IPC',
    'Lainnya',
  ];
  final List<String> _backupTypes = [
    'FO-Astinet',
    'FO-Astinet SDWAN',
    'FO-Icon',
    'FO-Icon SDWAN',
    'FO-Fiberstar SDWAN',
    'FO-Other',
    'OVPN-GSM Orbit',
    'OVPN-XL HO',
    'Vsat-IPC',
    'Lainnya',
    '-',
  ];

  final _gatewayController = TextEditingController();
  final _vsatController = TextEditingController();
  final _rbWdcpController = TextEditingController();
  final _station1Controller = TextEditingController();
  final _station2Controller = TextEditingController();
  final _station3Controller = TextEditingController();
  final _station4Controller = TextEditingController();
  final _station5Controller = TextEditingController();
  final _stbController = TextEditingController();
  final _ikioskController = TextEditingController();
  final _timbanganController = TextEditingController();
  final _cctv1Controller = TextEditingController();
  final _cctv2Controller = TextEditingController();

  bool get isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
    if (isEdit) {
      final s = widget.store!;
      _codeController.text = s.storeCode;
      _nameController.text = s.storeName;
      _selectedConnection = _connectionTypes.contains(s.connectionType)
          ? s.connectionType
          : null;
      _selectedBackup = _backupTypes.contains(s.connectionBackup)
          ? s.connectionBackup
          : null;
      _gatewayController.text = s.ipGateway ?? '';
      _vsatController.text = s.ipVsat ?? '';
      _rbWdcpController.text = s.ipRbWdcp ?? '';
      _station1Controller.text = s.ipStation1 ?? '';
      _station2Controller.text = s.ipStation2 ?? '';
      _station3Controller.text = s.ipStation3 ?? '';
      _station4Controller.text = s.ipStation4 ?? '';
      _station5Controller.text = s.ipStation5 ?? '';
      _stbController.text = s.ipStb ?? '';
      _ikioskController.text = s.ipIkiosk ?? '';
      _timbanganController.text = s.ipTimbangan ?? '';
      _cctv1Controller.text = s.ipCctv1 ?? '';
      _cctv2Controller.text = s.ipCctv2 ?? '';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _gatewayController.dispose();
    _vsatController.dispose();
    _rbWdcpController.dispose();
    _station1Controller.dispose();
    _station2Controller.dispose();
    _station3Controller.dispose();
    _station4Controller.dispose();
    _station5Controller.dispose();
    _stbController.dispose();
    _ikioskController.dispose();
    _timbanganController.dispose();
    _cctv1Controller.dispose();
    _cctv2Controller.dispose();
    super.dispose();
  }

  String? valueOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'store_code': _codeController.text.trim(),
      'store_name': _nameController.text.trim(),
      'connection_type': _selectedConnection,
      'connection_backup': _selectedBackup,
      'ip_gateway': valueOrNull(_gatewayController),
      'ip_vsat': valueOrNull(_vsatController),
      'ip_rb_wdcp': valueOrNull(_rbWdcpController),
      'ip_station_1': valueOrNull(_station1Controller),
      'ip_station_2': valueOrNull(_station2Controller),
      'ip_station_3': valueOrNull(_station3Controller),
      'ip_station_4': valueOrNull(_station4Controller),
      'ip_station_5': valueOrNull(_station5Controller),
      'ip_stb': valueOrNull(_stbController),
      'ip_ikiosk': valueOrNull(_ikioskController),
      'ip_timbangan': valueOrNull(_timbanganController),
      'ip_cctv_1': valueOrNull(_cctv1Controller),
      'ip_cctv_2': valueOrNull(_cctv2Controller),
    };

    try {
      if (isEdit) {
        // 1. Update ke Supabase
        await Supabase.instance.client
            .from('stores')
            .update(data)
            .eq('id', widget.store!.id);

        // 2. Catat log Edit Toko
        await ActivityLogger.logAction(
          actionType: "EDIT_TOKO",
          description: "Mengubah data toko: ${_nameController.text.trim()}",
        );
      } else {
        // 1. Insert ke Supabase
        await Supabase.instance.client.from('stores').insert(data);

        // 2. Catat log Tambah Toko
        await ActivityLogger.logAction(
          actionType: "TAMBAH_TOKO",
          description:
              "Menambahkan data toko baru: ${_nameController.text.trim()}",
        );
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          isEdit
              ? "Data toko berhasil diperbarui!"
              : "Toko baru berhasil ditambahkan!",
          Colors.green,
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Ambil pesan asli dari sistem
        String errorMessage = e.message;

        // Jika error codenya 23505 (Data Duplikat/Sudah Ada)
        if (e.code == '23505') {
          errorMessage =
              "Gagal: Kode Toko '${_codeController.text.trim()}' sudah terdaftar!";
        }

        CustomSnackBar.show(context, errorMessage, const Color(0xFFFF6B6B));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(context, "Error: $e", const Color(0xFFFF6B6B));
      }
    }
  }

  // ==========================================
  // HELPER RESPONSIF UTAMA
  // Jika lebar >= threshold → Row (2 kolom)
  // Jika lebar < threshold  → Column (1 kolom)
  // Masing-masing child HARUS dibungkus Expanded
  // ==========================================
  Widget _twoCol({
    required Widget left,
    required Widget right,
    double threshold = 460,
    double spacing = 14,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth >= threshold) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
      },
    );
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInfoCard(),
                            const SizedBox(height: 20),
                            _buildIpCard(),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
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
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEdit ? "MENYIMPAN PERUBAHAN..." : "MENAMBAHKAN TOKO...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2,
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? "Edit Data Toko" : "Tambah Toko Baru",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            isEdit
                ? "${widget.store!.storeCode} — ${widget.store!.storeName}"
                : "Isi informasi dan data IP toko",
            style: TextStyle(color: context.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  // ==========================================
  // KARTU 1: INFORMASI UTAMA
  // ==========================================
  Widget _buildInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Informasi Utama",
            Icons.storefront_outlined,
            context.accentColor,
          ),
          const SizedBox(height: 20),

          // Kode Toko (flex 2) + Nama Toko (flex 3)
          // Pada layar sempit → dua baris full width
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 400;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFormField(
                        controller: _codeController,
                        label: "Kode Toko",
                        icon: Icons.qr_code_outlined,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _buildFormField(
                        controller: _nameController,
                        label: "Nama Toko",
                        icon: Icons.badge_outlined,
                        required: true,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      controller: _codeController,
                      label: "Kode Toko",
                      icon: Icons.qr_code_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _buildFormField(
                      controller: _nameController,
                      label: "Nama Toko",
                      icon: Icons.badge_outlined,
                      required: true,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // Koneksi Utama + Koneksi Backup
          _twoCol(
            threshold: 460,
            left: _buildFormDropdown(
              label: "Koneksi Utama",
              icon: Icons.cable_outlined,
              items: _connectionTypes,
              value: _selectedConnection,
              onChanged: (val) => setState(() => _selectedConnection = val),
              accentColor: const Color(0xFF00E676),
            ),
            right: _buildFormDropdown(
              label: "Koneksi Backup",
              icon: Icons.settings_backup_restore_outlined,
              items: _backupTypes,
              value: _selectedBackup,
              onChanged: (val) => setState(() => _selectedBackup = val),
              accentColor: const Color(0xFFFFB347),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KARTU 2: IP ADDRESS
  // ==========================================
  Widget _buildIpCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            "Pengaturan IP Address",
            Icons.device_hub_outlined,
            const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 20),

          // JARINGAN UTAMA
          _buildIpSubSection(
            title: "JARINGAN UTAMA",
            color: context.accentColor,
            icon: Icons.wifi_outlined,
            children: [
              _twoCol(
                left: _buildFormField(
                  controller: _gatewayController,
                  label: "IP Gateway",
                  hint: "10.x.x.x",
                  icon: Icons.router_outlined,
                  isIp: true,
                ),
                right: _buildFormField(
                  controller: _vsatController,
                  label: "IP VSAT",
                  hint: "10.x.x.x",
                  icon: Icons.satellite_alt_outlined,
                  isIp: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _rbWdcpController,
                label: "IP RB WDCP",
                hint: "10.x.x.x",
                icon: Icons.settings_input_antenna_outlined,
                isIp: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // STATION / KASIR
          _buildIpSubSection(
            title: "STATION / KASIR",
            color: const Color(0xFF00C9A7),
            icon: Icons.point_of_sale_outlined,
            children: [
              _twoCol(
                left: _buildFormField(
                  controller: _station1Controller,
                  label: "Station 1",
                  hint: "10.x.x.x",
                  icon: Icons.computer_outlined,
                  isIp: true,
                ),
                right: _buildFormField(
                  controller: _station2Controller,
                  label: "Station 2",
                  hint: "10.x.x.x",
                  icon: Icons.computer_outlined,
                  isIp: true,
                ),
              ),
              const SizedBox(height: 12),
              _twoCol(
                left: _buildFormField(
                  controller: _station3Controller,
                  label: "Station 3",
                  hint: "10.x.x.x",
                  icon: Icons.computer_outlined,
                  isIp: true,
                ),
                right: _buildFormField(
                  controller: _station4Controller,
                  label: "Station 4",
                  hint: "10.x.x.x",
                  icon: Icons.computer_outlined,
                  isIp: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _station5Controller,
                label: "Station 5",
                hint: "10.x.x.x",
                icon: Icons.computer_outlined,
                isIp: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // PERANGKAT LAINNYA
          _buildIpSubSection(
            title: "PERANGKAT LAINNYA",
            color: const Color(0xFFFFB347),
            icon: Icons.devices_outlined,
            children: [
              _twoCol(
                left: _buildFormField(
                  controller: _stbController,
                  label: "IP STB",
                  hint: "10.x.x.x",
                  icon: Icons.tv_outlined,
                  isIp: true,
                ),
                right: _buildFormField(
                  controller: _ikioskController,
                  label: "IP iKiosk",
                  hint: "10.x.x.x",
                  icon: Icons.touch_app_outlined,
                  isIp: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                controller: _timbanganController,
                label: "IP Timbangan",
                hint: "10.x.x.x",
                icon: Icons.scale_outlined,
                isIp: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // CCTV / NVR
          _buildIpSubSection(
            title: "CCTV / NVR",
            color: const Color(0xFFFF6B6B),
            icon: Icons.videocam_outlined,
            children: [
              _twoCol(
                left: _buildFormField(
                  controller: _cctv1Controller,
                  label: "CCTV 1",
                  hint: "10.x.x.x",
                  icon: Icons.videocam_outlined,
                  isIp: true,
                ),
                right: _buildFormField(
                  controller: _cctv2Controller,
                  label: "CCTV 2",
                  hint: "10.x.x.x",
                  icon: Icons.videocam_outlined,
                  isIp: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: context.accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveData,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor,
                  context.accentColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEdit ? Icons.save_outlined : Icons.add_circle_outline,
                  color: context.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? "Simpan Perubahan" : "Simpan Toko Baru",
                  style: TextStyle(
                    color: context.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
      child: child,
    );
  }

  Widget _buildCardHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIpSubSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    bool isIp = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                "*",
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // --- BUNGKUS TEXTFORMFIELD DENGAN THEME ---
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: context.accentColor, // Warna kursor
              selectionColor: context.accentColor.withOpacity(
                0.3,
              ), // Warna blok teks
              selectionHandleColor:
                  context.accentColor, // Warna pentolan kursor di HP
            ),
          ),
          child: TextFormField(
            controller: controller,
            cursorColor: context.accentColor, // Penegasan kursor
            keyboardType: isIp ? TextInputType.number : TextInputType.text,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontFamily: isIp ? 'monospace' : null,
              letterSpacing: isIp ? 0.5 : 0,
            ),
            validator: required
                ? (value) =>
                      (value == null || value.isEmpty) ? 'Wajib diisi' : null
                : null,
            decoration: InputDecoration(
              hintText: hint ?? 'Masukkan $label',
              hintStyle: TextStyle(
                color: context.textSecondary.withOpacity(0.4),
                fontSize: 12,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 16, color: context.textSecondary)
                  : null,
              filled: true,
              fillColor: context.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B6B),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B6B),
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 10,
              ),
            ),
          ),
        ),

        // ------------------------------------------
      ],
    );
  }

  Widget _buildFormDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required Color accentColor,
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
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: context.cardColor,
          isExpanded:
              true, // <-- penting: cegah overflow teks di dropdown sempit
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.textSecondary,
            size: 18,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: context.textSecondary),
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
          items: items
              .map(
                (val) => DropdownMenuItem(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
