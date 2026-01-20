import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html; // WEB ONLY

import '../config/api_config.dart';
import '../models/student_login_response.dart';
import '../models/student_response_dto.dart';
import '../models/student_profile_dto.dart';

class WebStudentService { // Nama Class BEDA
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_token');
  }
  
  // --- [AUTH: LOGIN, REGISTER, DLL SAMA PERSIS, COPY SAJA] ---
  // Saya singkat agar fokus ke bagian download
  
  Future<StudentLoginResponse> login({required String email, required String password}) async {
     // ... (Copy logika login Anda disini) ...
     // Pastikan endpoint benar
     return StudentLoginResponse(); // Dummy return biar ga error
  }
  
  // ... (Fungsi Register, OTP, Profile, dll copy paste saja) ...

  // --- BAGIAN DOWNLOAD YANG 100% AMAN UNTUK WEB ---
  Future<String?> exportAttendance(String type) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Sesi tidak valid.");

      String endpoint = type == 'pdf' ? "/export/pdf" : "/export/excel";
      final fullUrl = "${ApiConfig.baseUrl}/v1/student$endpoint"; 

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes, 
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = type == 'pdf' ? 'pdf' : 'xlsx';
        final fileName = "Student_Report_$timestamp.$ext";

        // --- MURNI WEB LOGIC (TANPA IF-ELSE) ---
        final List<int> bytes = List<int>.from(response.data);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
          
        return "Success Web Download";
      }
      return null;
    } catch (e) {
      throw Exception("Gagal download: $e");
    }
  }
}