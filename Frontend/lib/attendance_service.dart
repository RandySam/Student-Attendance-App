import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 

import '../config/api_config.dart'; 
import '../models/student_attendance_dto.dart'; 

class AttendanceService {
  // Instance Dio khusus untuk download file
  final Dio _dio = Dio(); 

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_token'); 
  }

  Future<String?> _getNim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_nim');
  }

  // ===========================================================================
  // 1. GET HISTORY (Untuk Halaman History - Mengembalikan LIST)
  // ===========================================================================
  Future<List<StudentAttendanceDTO>> getHistory() async {
    final token = await _getToken();
    final nim = await _getNim();

    if (nim == null) throw Exception("NIM tidak ditemukan di sesi");

    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/history/$nim');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print("RAW JSON FROM API = ${response.body}");
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => StudentAttendanceDTO.fromJson(item)).toList();
    } else if (response.statusCode == 404) {
      return []; 
    } else {
      throw Exception('Gagal memuat history: ${response.statusCode}');
    }
  }

  // ===========================================================================
  // 2. GET MY ATTENDANCE (Untuk Dashboard - Mengembalikan SATU Data Hari Ini)
  // ===========================================================================
  Future<StudentAttendanceDTO?> getMyAttendance() async {
    try {
      List<StudentAttendanceDTO> allData = await getHistory();
      
      if (allData.isEmpty) return null;

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      try {
        return allData.firstWhere(
          (element) => element.attendanceDate == todayDate
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // 3. CLOCK IN
  // ===========================================================================
  Future<StudentAttendanceDTO> clockIn({
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    final nim = await _getNim();

    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/clock-in');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentNim': nim,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StudentAttendanceDTO.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Clock In Gagal');
    }
  }

  // ===========================================================================
  // 4. CLOCK OUT
  // ===========================================================================
  Future<StudentAttendanceDTO> clockOut({
    required double latitude,
    required double longitude,
  }) async {
    final token = await _getToken();
    final nim = await _getNim();

    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/clock-out');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentNim': nim,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StudentAttendanceDTO.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Clock Out Gagal');
    }
  }

  // ===========================================================================
  // 5. EXPORT (PDF & EXCEL) - DIPERBARUI
  // Mengirim NIM di URL agar Backend tidak perlu mencari via Email Token
  // ===========================================================================
  Future<String?> exportAttendance(String type) async {
    try {
      final token = await _getToken();
      // 1. Ambil NIM
      final nim = await _getNim(); 

      if (token == null) throw Exception("Token tidak valid");
      if (nim == null) throw Exception("NIM tidak ditemukan"); // Validasi NIM

      String endpoint = "";
      String extension = "";

      // 2. Masukkan NIM ke dalam URL Endpoint
      // Pastikan Controller Backend sudah menerima @PathVariable studentNim
      if (type == 'pdf') {
        endpoint = "/v1/student/export/pdf/$nim"; 
        extension = "pdf";
      } else {
        endpoint = "/v1/student/export/excel/$nim"; 
        extension = "xlsx";
      }

      final fullUrl = "${ApiConfig.baseUrl}$endpoint";

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) {
            return status! < 500; 
          }
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "Laporan_Absensi_$timestamp.$extension";
        final filePath = "${directory.path}/$fileName";

        File file = File(filePath);
        await file.writeAsBytes(response.data);

        return filePath; 
      } else {
        throw Exception("Gagal export: ${response.statusCode} - ${response.statusMessage}");
      }

    } on DioException catch (e) {
      throw Exception("Terjadi kesalahan koneksi: ${e.message}");
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}