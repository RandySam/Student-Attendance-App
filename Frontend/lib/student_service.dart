import 'dart:convert';
import 'dart:io' show File; 
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html; 
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/api_config.dart';
import '../models/student_login_response.dart';
import '../models/student_response_dto.dart';
import '../models/student_profile_dto.dart';
import '../models/student_attendance_dto.dart'; 

class StudentService {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_token');
  }

  Future<String?> _getNim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_nim');
  }

  // ====================================================================
  // 1. AUTHENTICATION
  // ====================================================================
  
  Future<StudentLoginResponse> login({required String email, required String password}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/login'); 
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'studentEmail': email, 'studentPassword': password}),
    );
    
    final data = jsonDecode(response.body);
    final loginResponse = StudentLoginResponse.fromJson(data);

    if (response.statusCode == 200) {
      if (loginResponse.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_token', loginResponse.token!);
        await _fetchAndSaveNim(loginResponse.token!); 
        return loginResponse;
      } else {
        throw Exception(loginResponse.message ?? 'Email atau password salah');
      }
    } else {
      throw Exception(loginResponse.message ?? 'Gagal terhubung ke server');
    }
  }

  Future<StudentResponseDTO> register({required String name, required String nim, required String email, required String password}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/register');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name, 'nim': nim, 'email': email, 'password': password}));
    final data = jsonDecode(response.body);
    final registerResponse = StudentResponseDTO.fromJson(data);
    if ((response.statusCode == 200 || response.statusCode == 201) && registerResponse.success) return registerResponse;
    throw Exception(registerResponse.message ?? 'Registrasi gagal');
  }

  // --- BAGIAN YANG DIPERBAIKI ---
  // Mengembalikan true jika status 200, tanpa peduli token
  Future<bool> verifyOtp({required String email, required String otp}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/verify-otp');
    
    final response = await http.post(
      url, 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({'studentEmail': email, 'otpCode': otp})
    );
    
    final data = jsonDecode(response.body);

    // Jika Status 200 OK, kita anggap SUKSES
    if (response.statusCode == 200) {
       return true; 
    }
    
    // Jika tidak 200, lempar error agar ditangkap catch di UI
    throw Exception(data['message'] ?? 'OTP tidak valid atau kadaluarsa');
  }
  // -----------------------------

  Future<StudentResponseDTO> resendOtp({required String email}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/resend-otp');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'studentEmail': email}));
    final data = jsonDecode(response.body);
    final resendResponse = StudentResponseDTO.fromJson(data);
    if (response.statusCode == 200 && resendResponse.success) return resendResponse;
    throw Exception(resendResponse.message ?? 'Gagal mengirim ulang OTP');
  }

  // ====================================================================
  // 1b. FORGOT PASSWORD FLOW
  //    Sesuai endpoint backend:
  //    POST /v1/student/forgot-password
  //    POST /v1/student/verify-forgot-otp
  //    POST /v1/student/reset-password
  // ====================================================================

  /// 1. Kirim email untuk minta OTP reset password
  Future<void> requestPasswordReset({required String email}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // sesuaikan dengan field di ForgotPasswordRequestDTO
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);
    final dto = StudentResponseDTO.fromJson(data);

    if (response.statusCode == 200 && dto.success) {
      // sukses, tidak perlu return apa-apa
      return;
    }

    throw Exception(dto.message ?? 'Gagal mengirim OTP reset password');
  }

  /// 2. Verifikasi OTP untuk forgot password
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/v1/student/verify-forgot-otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // sesuaikan dengan ForgotPasswordVerifyDTO
        'email': email,
        'otp': otp,
      }),
    );

    final data = jsonDecode(response.body);
    final dto = StudentResponseDTO.fromJson(data);

    if (response.statusCode == 200 && dto.success) {
      return; // OTP valid
    }

    throw Exception(dto.message ?? 'OTP reset password tidak valid atau kadaluarsa');
  }

  /// 3. Kirim password baru + OTP ke backend
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // sesuaikan dengan ResetPasswordRequestDTO
        'email': email,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    final dto = StudentResponseDTO.fromJson(data);

    if (response.statusCode == 200 && dto.success) {
      return; // password berhasil di-reset
    }

    throw Exception(dto.message ?? 'Gagal mengubah password');
  }



  Future<void> _fetchAndSaveNim(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/profile');
      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = StudentProfileDTO.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_nim', profile.studentNim); 
      }
    } catch (e) {
      print("Gagal fetch NIM: $e");
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // ====================================================================
  // 2. DASHBOARD (CLOCK IN/OUT & AUTO ABSENT)
  // ====================================================================

  Future<StudentAttendanceDTO?> getMyAttendance() async {
    try {
      List<StudentAttendanceDTO> history = await getHistory();
      
      await _checkAndSubmitAbsent(history);

      if (history.isEmpty) return null;
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      try {
        return history.firstWhere((element) => element.attendanceDate == today);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkAndSubmitAbsent(List<StudentAttendanceDTO> history) async {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    String yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    bool hasRecordYesterday = history.any((e) => e.attendanceDate == yesterdayStr);

    if (!hasRecordYesterday) {
      await _submitAbsent(yesterdayStr);
    }
  }

  Future<void> _submitAbsent(String date) async {
    try {
       final token = await _getToken();
       final nim = await _getNim();
       
       final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/absent'); 
       
       await http.post(
         url,
         headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
         body: jsonEncode({'studentNim': nim, 'date': date, 'status': 'Absent'}),
       );
       print("Auto Absent Submitted for $date");
    } catch (e) {
       print("Failed to submit absent: $e");
    }
  }

  Future<StudentAttendanceDTO> clockIn({required double latitude, required double longitude}) async {
    final token = await _getToken();
    final nim = await _getNim();
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/clock-in');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'studentNim': nim, 'latitude': latitude, 'longitude': longitude}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StudentAttendanceDTO.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Clock In Gagal');
    }
  }

  Future<StudentAttendanceDTO> clockOut({required double latitude, required double longitude}) async {
    final token = await _getToken();
    final nim = await _getNim();
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/clock-out');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'studentNim': nim, 'latitude': latitude, 'longitude': longitude}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return StudentAttendanceDTO.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Clock Out Gagal');
    }
  }

  // ====================================================================
  // 3. PROFILE & HISTORY
  // ====================================================================

  Future<StudentProfileDTO> getProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception("Sesi tidak valid."); 
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/profile');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return StudentProfileDTO.fromJson(jsonDecode(response.body));
    throw Exception('Gagal mengambil profil');
  }

  Future<StudentProfileDTO> updateProfile({required String telephone, required String address, required String major}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Sesi tidak valid.");
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/profile');
    final response = await http.put(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'studentTelephone': telephone, 'studentAddress': address, 'studentMajor': major}));
    if (response.statusCode == 200) return StudentProfileDTO.fromJson(jsonDecode(response.body));
    throw Exception('Gagal memperbarui profil');
  }

  Future<List<StudentAttendanceDTO>> getHistory() async {
    final token = await _getToken();
    final nim = await _getNim(); 
    if (token == null || nim == null) return []; 
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/student/attendance/history/$nim');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => StudentAttendanceDTO.fromJson(item)).toList();
    } else if (response.statusCode == 404) return [];
    throw Exception('Gagal memuat history: ${response.statusCode}');
  }
  

  // ====================================================================
  // 4. EXPORT (CSV)
  // ====================================================================
  Future<String?> exportAttendance(String type) async {
    try {
      final token = await _getToken();
      final nim = await _getNim();

      if (token == null) throw Exception("Sesi tidak valid.");
      if (nim == null) throw Exception("NIM tidak ditemukan.");

      final endpoint = type == 'pdf'
          ? "/v1/student/export/pdf/$nim"
          : "/v1/student/export/csv/$nim";

      final fullUrl = "${ApiConfig.baseUrl}$endpoint";

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 404) {
        throw Exception("File tidak ditemukan (404).");
      }

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = type == 'pdf' ? 'pdf' : 'csv';
        final filename = "Attendance_Report_$timestamp.$ext";

        if (kIsWeb) {
          final bytes = List<int>.from(response.data);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", filename)
            ..click();
          html.Url.revokeObjectUrl(url);
          return "Download sukses (Web)";
        }

        final dir = await getApplicationDocumentsDirectory();
        final path = "${dir.path}/$filename";

        final file = File(path);
        
        await file.writeAsBytes(response.data, flush: true);

        return path;
      }

      throw Exception("Gagal export: ${response.statusCode}");
    } catch (e) {
      throw Exception("Gagal download: $e");
    }
  }
  
}