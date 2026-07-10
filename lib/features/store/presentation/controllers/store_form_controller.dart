import 'package:flutter/material.dart';

import '../../../../core/utils/notification_mixin.dart';
import '../../data/store_repository.dart';
import '../../domain/store_model.dart';

/// StoreFormController — semua state dan logic untuk StoreFormPage.
///
/// Lokasi: features/store/presentation/controllers/store_form_controller.dart
///
/// Tanggung jawab:
///   - Kelola TextEditingController untuk 17 field input
///   - Kelola toggle aktif/nonaktif perangkat
///   - Auto-fill IP berdasarkan Gateway/VSAT
///   - Validasi dan submit data ke repository
///   - Loading state
///
/// TIDAK BOLEH:
///   - Menampilkan Snackbar langsung
///   - Import widget UI
///   - Query Supabase langsung (harus via repository)
///
class StoreFormController extends ChangeNotifier with NotificationMixin {
  final StoreRepository _repo;
  final StoreModel? existingStore;

  StoreFormController({StoreRepository? repo, this.existingStore})
    : _repo = repo ?? StoreRepository();

  // ── Mode ─────────────────────────────────────────────────────
  bool get isEdit => existingStore != null;

  // ── State: Loading ──────────────────────────────────────────
  bool isLoading = false;

  // ── State: Form berhasil disimpan → Page harus pop ─────────
  bool savedSuccessfully = false;

  // ── Constants ─────────────────────────────────────────────────
  static const List<String> connectionTypes = [
    'FO-Astinet',
    'FO-Astinet SDWAN',
    'FO-Icon',
    'FO-Icon SDWAN',
    'FO-Fiberstar SDWAN',
    'Starlink SDWAN',
    'FO-Other',
    'OVPN-GSM Orbit',
    'OVPN-XL HO',
    'Vsat-IPC',
    'Lainnya',
  ];

  static const List<String> backupTypes = [
    'FO-Astinet',
    'FO-Astinet SDWAN',
    'FO-Icon',
    'FO-Icon SDWAN',
    'FO-Fiberstar SDWAN',
    'Starlink SDWAN',
    'FO-Other',
    'OVPN-GSM Orbit',
    'OVPN-XL HO',
    'Vsat-IPC',
    'Lainnya',
    '-',
  ];

  // ── TextEditingControllers ──────────────────────────────────
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final sidUtamaController = TextEditingController();
  final sidBackupController = TextEditingController();
  final gatewayController = TextEditingController();
  final vsatController = TextEditingController();
  final rbWdcpController = TextEditingController();
  final station1Controller = TextEditingController();
  final station2Controller = TextEditingController();
  final station3Controller = TextEditingController();
  final station4Controller = TextEditingController();
  final station5Controller = TextEditingController();
  final stbController = TextEditingController();
  final ikioskController = TextEditingController();
  final timbanganController = TextEditingController();
  final cctv1Controller = TextEditingController();
  final cctv2Controller = TextEditingController();

  // ── State: Dropdown selections ──────────────────────────────
  String? selectedConnection;
  String? selectedBackup;

  // ── State: Toggle aktif/nonaktif per perangkat ──────────────
  bool station1Active = true;
  bool station2Active = true;
  bool station3Active = true;
  bool station4Active = false;
  bool station5Active = false;
  bool ikioskActive = false;
  bool timbanganActive = false;

  /// Daftar semua IP controllers untuk batch operations.
  List<TextEditingController> get _allIpControllers => [
    gatewayController,
    vsatController,
    rbWdcpController,
    station1Controller,
    station2Controller,
    station3Controller,
    station4Controller,
    station5Controller,
    stbController,
    ikioskController,
    timbanganController,
    cctv1Controller,
    cctv2Controller,
  ];

  // ── INISIALISASI ────────────────────────────────────────────
  /// Panggil sekali saat page init. Mengisi field dari store jika edit mode.
  void init() {
    // Auto-fill listener — aktif hanya untuk toko baru
    if (!isEdit) {
      gatewayController.addListener(_onGatewayChanged);
      vsatController.addListener(_onVsatChanged);
    }

    if (isEdit) {
      final s = existingStore!;
      codeController.text = s.storeCode;
      nameController.text = s.storeName;
      selectedConnection = connectionTypes.contains(s.connectionType)
          ? s.connectionType
          : null;
      selectedBackup = backupTypes.contains(s.connectionBackup)
          ? s.connectionBackup
          : null;
      sidUtamaController.text = s.sidUtama ?? '';
      sidBackupController.text = s.sidBackup ?? '';
      gatewayController.text = s.ipGateway ?? '';
      vsatController.text = s.ipVsat ?? '';
      rbWdcpController.text = s.ipRbWdcp ?? '';
      station1Controller.text = s.ipStation1 ?? '';
      station2Controller.text = s.ipStation2 ?? '';
      station3Controller.text = s.ipStation3 ?? '';
      station4Controller.text = s.ipStation4 ?? '';
      station5Controller.text = s.ipStation5 ?? '';
      stbController.text = s.ipStb ?? '';
      ikioskController.text = s.ipIkiosk ?? '';
      timbanganController.text = s.ipTimbangan ?? '';
      cctv1Controller.text = s.ipCctv1 ?? '';
      cctv2Controller.text = s.ipCctv2 ?? '';

      // Toggle: ON jika IP sudah ada di database
      station1Active = (s.ipStation1 ?? '').isNotEmpty;
      station2Active = (s.ipStation2 ?? '').isNotEmpty;
      station3Active = (s.ipStation3 ?? '').isNotEmpty;
      station4Active = (s.ipStation4 ?? '').isNotEmpty;
      station5Active = (s.ipStation5 ?? '').isNotEmpty;
      ikioskActive = (s.ipIkiosk ?? '').isNotEmpty;
      timbanganActive = (s.ipTimbangan ?? '').isNotEmpty;
    }
  }

  // ── UPDATE STATE ────────────────────────────────────────────

  void setConnection(String? val) {
    selectedConnection = val;
    notifyListeners();
  }

  void setBackup(String? val) {
    selectedBackup = val;
    notifyListeners();
  }

  void setToggle(String field, bool value) {
    switch (field) {
      case 'station1':
        station1Active = value;
      case 'station2':
        station2Active = value;
      case 'station3':
        station3Active = value;
      case 'station4':
        station4Active = value;
      case 'station5':
        station5Active = value;
      case 'ikiosk':
        ikioskActive = value;
      case 'timbangan':
        timbanganActive = value;
    }
    notifyListeners();
  }

  // ── CLEAR ALL IP ────────────────────────────────────────────
  void clearAllIp() {
    for (final c in _allIpControllers) {
      c.value = c.value.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  // ── AUTO-FILL IP ────────────────────────────────────────────
  /// VSAT prioritas utama, Gateway sebagai fallback.
  /// Jika VSAT valid → selalu pakai VSAT sebagai acuan (dual koneksi).
  /// Jika VSAT kosong & Gateway valid → pakai Gateway sebagai acuan.

  void _onVsatChanged() => _autoFill(vsatController.text.trim());

  void _onGatewayChanged() {
    // Hanya jalankan auto-fill dari gateway jika VSAT belum diisi
    final vsatFilled =
        vsatController.text.trim().split('.').length == 4 &&
        int.tryParse(vsatController.text.trim().split('.').last) != null;
    if (!vsatFilled) _autoFill(gatewayController.text.trim());
  }

  void _autoFill(String baseIp) {
    final parts = baseIp.split('.');
    if (parts.length != 4) return;
    final base = int.tryParse(parts[3]);
    if (base == null) return;
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    void set(TextEditingController c, int offset) {
      final val = '$prefix.${base + offset}';
      if (c.text != val) {
        c.value = c.value.copyWith(
          text: val,
          selection: TextSelection.collapsed(offset: val.length),
        );
      }
    }

    set(station1Controller, 1);
    set(station2Controller, 2);
    set(station3Controller, 3);
    set(station4Controller, 4);
    set(station5Controller, 5);
    set(rbWdcpController, 19);
    set(stbController, 17);
    set(ikioskController, 20);
    set(timbanganController, 24);
    set(cctv1Controller, 26);
    set(cctv2Controller, 27);
  }

  // ── HELPERS ─────────────────────────────────────────────────

  String? _valueOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// Membangun Map data untuk dikirim ke repository.
  Map<String, dynamic> _buildFormData() {
    return {
      'store_code': codeController.text.trim(),
      'store_name': nameController.text.trim(),
      'connection_type': selectedConnection,
      'connection_backup': selectedBackup,
      'sid_utama': _valueOrNull(sidUtamaController),
      'sid_backup': _valueOrNull(sidBackupController),
      'ip_gateway': _valueOrNull(gatewayController),
      'ip_vsat': _valueOrNull(vsatController),
      'ip_rb_wdcp': _valueOrNull(rbWdcpController),
      'ip_station_1': station1Active ? _valueOrNull(station1Controller) : null,
      'ip_station_2': station2Active ? _valueOrNull(station2Controller) : null,
      'ip_station_3': station3Active ? _valueOrNull(station3Controller) : null,
      'ip_station_4': station4Active ? _valueOrNull(station4Controller) : null,
      'ip_station_5': station5Active ? _valueOrNull(station5Controller) : null,
      'ip_stb': _valueOrNull(stbController),
      'ip_ikiosk': ikioskActive ? _valueOrNull(ikioskController) : null,
      'ip_timbangan': timbanganActive
          ? _valueOrNull(timbanganController)
          : null,
      'ip_cctv_1': _valueOrNull(cctv1Controller),
      'ip_cctv_2': _valueOrNull(cctv2Controller),
    };
  }

  // ── SAVE / UPDATE ───────────────────────────────────────────
  /// Validasi form → build data → kirim ke repo.
  /// Return true jika berhasil (Page harus pop).
  Future<void> saveData(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    notifyListeners();

    final data = _buildFormData();

    final result = isEdit
        ? await _repo.update(existingStore!.id, data)
        : await _repo.insert(data);

    result.fold(
      (failure) {
        isLoading = false;
        notifyError(failure.message);
        notifyListeners();
      },
      (_) {
        notifySuccess(
          isEdit
              ? 'Data toko berhasil diperbarui!'
              : 'Toko baru berhasil ditambahkan!',
        );
        savedSuccessfully = true;
        notifyListeners();
      },
    );
  }

  // ── DISPOSE ─────────────────────────────────────────────────
  @override
  void dispose() {
    if (!isEdit) {
      gatewayController.removeListener(_onGatewayChanged);
      vsatController.removeListener(_onVsatChanged);
    }
    codeController.dispose();
    nameController.dispose();
    sidUtamaController.dispose();
    sidBackupController.dispose();
    gatewayController.dispose();
    vsatController.dispose();
    rbWdcpController.dispose();
    station1Controller.dispose();
    station2Controller.dispose();
    station3Controller.dispose();
    station4Controller.dispose();
    station5Controller.dispose();
    stbController.dispose();
    ikioskController.dispose();
    timbanganController.dispose();
    cctv1Controller.dispose();
    cctv2Controller.dispose();
    super.dispose();
  }
}
