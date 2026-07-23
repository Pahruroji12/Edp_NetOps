import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edp_netops/core/platform/native_io.dart';
import 'package:edp_netops/core/utils/notification_mixin.dart';
import 'package:edp_netops/core/utils/tool_helper.dart';
import 'package:edp_netops/features/settings/data/settings_repository.dart';

class AlarmServer {
  final String id;
  final String label;
  final String host;
  final int port;
  final String username;
  final String password;
  final String database;
  bool isSelected;
  bool? isOnline;
  int? latencyMs;
  bool isChecking;

  AlarmServer({
    required this.id,
    required this.label,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.database,
    this.isSelected = true,
    this.isOnline,
    this.latencyMs,
    this.isChecking = false,
  });
}

class AlarmRecipient {
  final String id;
  final int urutan;
  final String jabatan;
  final String nik;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  AlarmRecipient({
    required this.id,
    required this.urutan,
    required this.jabatan,
    required this.nik,
    required String defaultNama,
    required String defaultNoHp,
  }) : nameCtrl = TextEditingController(text: defaultNama),
       phoneCtrl = TextEditingController(text: defaultNoHp);

  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class AlarmLogLine {
  final DateTime timestamp;
  final String type; // '[system]', '[info]', '[error]', '[success]'
  final String message;

  AlarmLogLine({
    required this.timestamp,
    required this.type,
    required this.message,
  });
}

class AlarmTestController extends ChangeNotifier with NotificationMixin {
  // Singleton: hidup selama aplikasi berjalan agar log tidak hilang
  static final AlarmTestController instance = AlarmTestController._();

  final _client = Supabase.instance.client;

  bool isLoading = false;
  bool isTesting = false;
  double progressValue = 0.0;

  // Form Inputs (Hanya Kode Toko & No Telepon Alarm yang editable)
  final shopCodeCtrl = TextEditingController(text: 'TEDP');
  final phoneAlarmCtrl = TextEditingController(text: '08131920101');

  List<AlarmServer> servers = [];
  List<AlarmRecipient> recipients = [];
  List<AlarmLogLine> logs = [];

  AlarmTestController._();

  String _formatDateTime(DateTime dt) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return "${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}";
  }

  /// Memuat data konfigurasi server dan penerima default dari Supabase
  Future<void> loadConfig() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Ambil DB servers
      final serverRes = await _client
          .from('alarm_db_servers')
          .select()
          .order('server_label', ascending: true);

      servers = (serverRes as List).map((item) {
        return AlarmServer(
          id: (item['id'] ?? '').toString(),
          label: (item['server_label'] ?? '').toString(),
          host: (item['host'] ?? '').toString(),
          port: int.tryParse(item['port']?.toString() ?? '3306') ?? 3306,
          username: (item['username'] ?? '').toString(),
          password: (item['password'] ?? '').toString(),
          database: (item['database_name'] ?? '').toString(),
        );
      }).toList();

      // 2. Ambil Default Recipients
      final recipientRes = await _client
          .from('alarm_test_default_recipients')
          .select()
          .order('urutan', ascending: true);

      for (var r in recipients) {
        r.dispose();
      }
      recipients = (recipientRes as List).map((item) {
        return AlarmRecipient(
          id: (item['id'] ?? '').toString(),
          urutan: int.tryParse(item['urutan']?.toString() ?? '0') ?? 0,
          jabatan: (item['jabatan'] ?? '').toString(),
          nik: (item['default_nik'] ?? '').toString(),
          defaultNama: (item['default_nama'] ?? '').toString(),
          defaultNoHp: (item['default_no_hp'] ?? '').toString(),
        );
      }).toList();
    } catch (e) {
      notifyError('Gagal memuat konfigurasi: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Menjalankan ping port / test connection ke MySQL Server
  Future<void> testConnection(AlarmServer server) async {
    server.isChecking = true;
    server.isOnline = null;
    server.latencyMs = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    MySQLConnection? conn;
    try {
      conn = await MySQLConnection.createConnection(
        host: server.host,
        port: server.port,
        userName: server.username,
        password: server.password,
        databaseName: server.database,
        secure: false,
      );
      await conn.connect();
      final res = await conn.execute("SELECT 1");
      if (res.rows.isNotEmpty) {
        server.isOnline = true;
        server.latencyMs = stopwatch.elapsedMilliseconds;
      } else {
        server.isOnline = false;
      }
    } catch (e) {
      server.isOnline = false;
      debugPrint(
        '[AlarmTestController] Connection test failed for ${server.label}: $e',
      );
    } finally {
      stopwatch.stop();
      if (conn != null) {
        try {
          await conn.close();
        } catch (_) {}
      }
      server.isChecking = false;
      notifyListeners();
    }
  }

  /// Luncurkan VNC Viewer ke IP DB Server
  Future<void> launchVnc(String ip) async {
    final vncPath = await ToolHelper.getVncPath();
    if (!await File(vncPath).exists()) {
      notifyError('VNC Viewer tidak ditemukan di: $vncPath');
      return;
    }

    final settingsResult = await SettingsRepository().fetchAppSettings();
    settingsResult.fold(
      (failure) =>
          notifyError('Gagal memuat konfigurasi VNC: ${failure.message}'),
      (data) {
        try {
          final password = data['vnc_alarm'] ?? '123';

          Process.start(vncPath, [
            ip,
            '/password',
            password,
          ], mode: ProcessStartMode.detached);
          notifySuccess('Membuka VNC ke $ip...');
        } catch (e) {
          notifyError('Gagal meluncurkan VNC: $e');
        }
      },
    );
  }

  // ── Console logging helpers ──
  void logSystem(String message) {
    logs.add(
      AlarmLogLine(
        timestamp: DateTime.now(),
        type: '[system]',
        message: message,
      ),
    );
    notifyListeners();
  }

  void logInfo(String message) {
    logs.add(
      AlarmLogLine(timestamp: DateTime.now(), type: '[info]', message: message),
    );
    notifyListeners();
  }

  void logError(String message) {
    logs.add(
      AlarmLogLine(
        timestamp: DateTime.now(),
        type: '[error]',
        message: message,
      ),
    );
    notifyListeners();
  }

  void logSuccess(String message) {
    logs.add(
      AlarmLogLine(
        timestamp: DateTime.now(),
        type: '[success]',
        message: message,
      ),
    );
    notifyListeners();
  }

  /// Eksekusi Test Dial Alarm (Insert data ke MySQL Servers)
  Future<void> runAlarmTest() async {
    isTesting = true;
    progressValue = 0.0;
    logs.clear();
    notifyListeners();

    // 1. Validasi Input (Tanggal di-update otomatis, Parameter lainnya fixed)
    final shop = shopCodeCtrl.text.trim();
    final phone = phoneAlarmCtrl.text.trim();
    const user = 'EDP';
    const code = 'G157';
    const sesi = 5;
    final tanggal = _formatDateTime(DateTime.now());

    if (shop.isEmpty || phone.isEmpty) {
      logError("Data input alarm tidak lengkap!");
      isTesting = false;
      notifyListeners();
      return;
    }

    final selectedServers = servers.where((s) => s.isSelected).toList();
    if (selectedServers.isEmpty) {
      logError("Pilih minimal 1 server database untuk diuji!");
      isTesting = false;
      notifyListeners();
      return;
    }

    logSystem("Memulai eksekusi dial alarm test...");

    int successCount = 0;
    int completedServers = 0;

    for (var server in selectedServers) {
      logInfo("Menghubungkan ke ${server.label} (${server.host})...");
      MySQLConnection? conn;
      try {
        conn = await MySQLConnection.createConnection(
          host: server.host,
          port: server.port,
          userName: server.username,
          password: server.password,
          databaseName: server.database,
          secure: false,
        );
        await conn.connect();
        logInfo("[${server.label}] Terhubung ke database MySQL.");

        // Dapatkan digit angka label untuk TEST ALARM LBK SERVER X
        final match = RegExp(r'\d+').firstMatch(server.label);
        final serverNum = match != null
            ? match.group(0)
            : (servers.indexOf(server) + 1).toString();

        final String ketAlarm = "TEST ALARM LBK SERVER $serverNum";

        // ── 1. HAPUS DATA LAMA ──
        logInfo("[${server.label}] Menghapus data test lama...");
        final delAlarmRes = await conn.execute(
          "DELETE FROM m_no_telfon_alarm_toko WHERE SHOP = :shop",
          {"shop": shop},
        );
        logInfo(
          "[${server.label}] Terhapus ${delAlarmRes.affectedRows} baris di m_no_telfon_alarm_toko.",
        );

        final delRecipRes = await conn.execute(
          "DELETE FROM m_registrasi_hp WHERE KODETOKO = :shop",
          {"shop": shop},
        );
        logInfo(
          "[${server.label}] Terhapus ${delRecipRes.affectedRows} baris di m_registrasi_hp.",
        );

        // ── 2. INPUT DATA ALARM BARU ──
        logInfo("[${server.label}] Memasukkan nomor alarm toko...");
        await conn.execute(
          "INSERT INTO m_no_telfon_alarm_toko VALUES (:shop, :ket, :no_hp, :sesi, :tgl, :user, :code)",
          {
            "shop": shop,
            "ket": ketAlarm,
            "no_hp": phone,
            "sesi": sesi,
            "tgl": tanggal,
            "user": user,
            "code": code,
          },
        );
        logSuccess("[${server.label}] Input m_no_telfon_alarm_toko BERHASIL.");

        // ── 3. INPUT DATA PENERIMA ──
        logInfo("[${server.label}] Memasukkan 4 penerima alarm default...");
        int recipSuccess = 0;

        final String serverNumStr = (serverNum ?? '1').padLeft(3, '0');
        final String ketRecip = "TEST ALARM LBK $serverNumStr";

        for (var recip in recipients) {
          final rName = recip.nameCtrl.text.trim();
          final rNik = recip.nik.trim();
          final rPhone = recip.phoneCtrl.text.trim();

          await conn.execute(
            "INSERT INTO m_registrasi_hp VALUES (:kodetoko, :ket, :nama, :nik, :jabatan, :nohp, :tgl_input, :ip_server, :tgl_update, :sesi, :urutan, :status)",
            {
              "kodetoko": shop,
              "ket": ketRecip,
              "nama": rName,
              "nik": rNik,
              "jabatan": recip.jabatan,
              "nohp": rPhone,
              "tgl_input": tanggal,
              "ip_server": server.host,
              "tgl_update": tanggal,
              "sesi": sesi,
              "urutan": recip.urutan,
              "status": "",
            },
          );
          recipSuccess++;
        }
        logSuccess(
          "[${server.label}] Input $recipSuccess penerima di m_registrasi_hp BERHASIL.",
        );
        successCount++;
      } catch (e) {
        logError("[${server.label}] Gagal mengeksekusi test: $e");
      } finally {
        if (conn != null) {
          try {
            await conn.close();
          } catch (_) {}
        }
        completedServers++;
        progressValue = completedServers / selectedServers.length;
        notifyListeners();
      }
    }

    if (successCount == selectedServers.length) {
      logSuccess("Seluruh eksekusi dial alarm selesai dan BERHASIL!");
    } else {
      logError(
        "Eksekusi dial alarm selesai dengan beberapa kegagalan ($successCount / ${selectedServers.length} sukses).",
      );
    }
    isTesting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    shopCodeCtrl.dispose();
    phoneAlarmCtrl.dispose();
    for (var r in recipients) {
      r.dispose();
    }
    super.dispose();
  }
}
