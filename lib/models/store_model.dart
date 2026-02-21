class StoreModel {
  final String id;
  final String storeCode;
  final String storeName;
  final bool isOnline;

  // Koneksi
  final String? connectionType; // Koneksi Utama
  final String? connectionBackup; // Koneksi Backup
  final String? ipVsat; // IP VSAT (Dual)

  // Network Infrastructure
  final String? ipGateway; // Mikrotik
  final String? ipRbWdcp; // RB WDCP

  // Station (Kasir/PC)
  final String? ipStation1;
  final String? ipStation2;
  final String? ipStation3;
  final String? ipStation4;
  final String? ipStation5;

  // Perangkat Toko
  final String? ipStb; // Set Top Box
  final String? ipIkiosk; // Price Checker
  final String? ipTimbangan; // Timbangan Digital

  // Security
  final String? ipCctv1;
  final String? ipCctv2;

  StoreModel({
    required this.id,
    required this.storeCode,
    required this.storeName,
    required this.isOnline,
    this.connectionType,
    this.connectionBackup,
    this.ipVsat,
    this.ipGateway,
    this.ipRbWdcp,
    this.ipStation1,
    this.ipStation2,
    this.ipStation3,
    this.ipStation4,
    this.ipStation5,
    this.ipStb,
    this.ipIkiosk,
    this.ipTimbangan,
    this.ipCctv1,
    this.ipCctv2,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      storeCode: json['store_code'] ?? '-',
      storeName: json['store_name'] ?? 'Tanpa Nama',
      isOnline: json['is_online'] ?? false,

      // Mapping sesuai nama kolom di Supabase
      connectionType: json['connection_type'],
      connectionBackup: json['connection_backup'],
      ipVsat: json['ip_vsat'],

      ipGateway: json['ip_gateway'],
      ipRbWdcp: json['ip_rb_wdcp'],

      ipStation1: json['ip_station_1'],
      ipStation2: json['ip_station_2'],
      ipStation3: json['ip_station_3'],
      ipStation4: json['ip_station_4'],
      ipStation5: json['ip_station_5'],

      ipStb: json['ip_stb'],
      ipIkiosk: json['ip_ikiosk'],
      ipTimbangan: json['ip_timbangan'],

      ipCctv1: json['ip_cctv_1'],
      ipCctv2: json['ip_cctv_2'],
    );
  }
}
