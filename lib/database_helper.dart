import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'items.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE t_estate(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            estate_code TEXT,
            estate_name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE t_pemanen(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pemanen TEXT,
            employee_code TEXT,
            estate_code TEXT,
            mandor_code TEXT,
            fc_code TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE t_block(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            block TEXT,
            divisi TEXT,
            abw TEXT,
            estate_code TEXT,
            tahun_tanam TEXT,
            harvest_method TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE t_tph(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tph TEXT,
            block TEXT,
            divisi TEXT,
            estate_code TEXT,
            lat TEXT,
            long TEXT,
            jarak TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE t_divisi(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            divisi TEXT,
            estate_code TEXT,
            company_code TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE t_input(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            oph_generate TEXT,
            code_tph TEXT,
            code_bcc TEXT,
            tanggal TEXT,
            divisi TEXT,
            block TEXT,
            pemanen TEXT,
            matang TEXT,
            kurang_matang TEXT,
            abnormal TEXT,
            tandan_kosong TEXT,
            brondolan TEXT,
            tangkai_panjang TEXT,
            jumlah_tandan TEXT,
            partheno TEXT,
            status_load TEXT,
            picture_tph TEXT,
            lat TEXT,
            long TEXT,
            flag_brondolan TEXT,
            flag_gps_location TEXT,
            status_hk TEXT
          )
        ''');

        await db.insert('t_estate', {'estate_code': 'ACB01', 'estate_name': 'CITRA RIAU SARANA'});
        await db.insert('t_estate', {'estate_code': 'ADB01', 'estate_name': 'WONOSARI'});
        await db.insert('t_estate', {'estate_code': 'ADB02', 'estate_name': 'SEI DERAS'});
        await db.insert('t_estate', {'estate_code': 'AMF01', 'estate_name': 'MURINI SAMSAM'});
        await db.insert('t_estate', {'estate_code': 'AMO01', 'estate_name': 'SEI DAUN'});
        await db.insert('t_estate', {'estate_code': 'BKF01', 'estate_name': 'KENCANA SAWIT INDONESIA'});
        await db.insert('t_estate', {'estate_code': 'CTC01', 'estate_name': 'BURNAI TIMUR'});
        await db.insert('t_estate', {'estate_code': 'CTC02', 'estate_name': 'BAMBU KUNING'});
        await db.insert('t_estate', {'estate_code': 'CTC03', 'estate_name': 'BURNAI BARAT'});
      },
    );
  }

  Future<List<Map<String, dynamic>>> getEstates() async {
    final dbClient = await db;
    return dbClient.query('t_estate');
  }

  Future<List<Map<String, dynamic>>> getBCC() async {
    final dbClient = await db;
    return dbClient.query('t_input');
  }

  Future<List<String>> getDivisi() async {
    final dbClient = await db;
    final result = await dbClient.query('t_divisi');

    return result.map((row) => row['divisi'].toString()).toList();
  }

  Future<List<String>> getPemanen() async {
    final dbClient = await db;
    final result = await dbClient.query('t_pemanen');

    return result.map((row) => row['pemanen'].toString()).toList();
  }

  Future<int> deleteItem(int id) async {
    final dbClient = await db;
    return await dbClient.delete('t_input', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getEstateCodeByName(String name) async {
    final dbClient = await db;
    final result = await dbClient.query('t_estate', where: 'estate_name = ?', whereArgs: [name]);
    if (result.isNotEmpty) {
      return result.first['estate_code'] as String;
    }
    return null;
  }

  Future<void> insertTph(Map<String, dynamic> data) async {
    final dbClient = await db;
    await dbClient.insert(
      't_tph',
      {
        'tph': data['TPH_Number'],
        'block': data['Block_Number'],
        'divisi': data['Divisi'],
        'estate_code': data['Estate_Code'],
        'lat': data['Lat'],
        'long': data['Long'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBlock(Map<String, dynamic> data) async {
    final dbClient = await db;
    await dbClient.insert(
      't_block',
      {
        'block': data['Block_Number'],
        'divisi': data['Divisi'],
        'abw': data['ABW'],
        'estate_code': data['Estate_Code'],
        'tahun_tanam': data['TahunTanam'],
        'harvest_method': data['harvestMethod'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertPemanen(Map<String, dynamic> data) async {
    final dbClient = await db;
    await dbClient.insert(
      't_pemanen',
      {
        'pemanen': data['Nomor_Pemanen'],
        'employee_code': data['Employee_code'],
        'estate_code': data['Estate_Code'],
        'mandor_code': data['MandorEmployeeCode'],
        'fc_code': data['FcCode'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDivisi(Map<String, dynamic> data) async {
    final dbClient = await db;
    await dbClient.insert(
      't_divisi',
      {
        'divisi': data['Divisi'],
        'estate_code': data['Estate_Code'],
        'company_code': data['Company_Code'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getBlockFromTPH(String tphValue, String divisi) async {
    final dbClient = await db; // replace with your DB instance
    final result = await dbClient.query(
      't_tph',
      columns: ['block'],
      where: 'tph = ? AND divisi = ?',
      whereArgs: [tphValue, divisi],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['block'] as String;
    }
    return null;
  }

  Future<void> clearAllTables() async {
    final dbClient = await db;
    await dbClient.delete('t_tph');
    await dbClient.delete('t_block');
    await dbClient.delete('t_pemanen');
    await dbClient.delete('t_divisi');
    await dbClient.delete('t_input');
  }
}
