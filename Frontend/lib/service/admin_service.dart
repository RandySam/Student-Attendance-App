import 'dart:convert';
// Import IO dan Path Provider (Aktifkan kembali untuk Mobile)
import 'dart:io' as io; 
import 'package:path_provider/path_provider.dart'; 

import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

// Import Web
import 'package:universal_html/html.dart' as html; 

import '../config/api_config.dart';
import '../models/admin_login_response.dart';
import '../models/admin_models.dart'; 

class AdminService {
  final Dio _dio = Dio(); 

  Future<AdminLoginResponse> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/v1/admin/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final loginResponse = AdminLoginResponse.fromJson(data);

      if (loginResponse.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', loginResponse.token!);
      }
      return loginResponse;
    } else {
      throw Exception('Login gagal: ${response.body}');
    }
  }

  Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    return token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }


  Future<List<StudentListItemDTO>> searchStudents({String? keyword, String? startDate, String? endDate}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Sesi habis, silakan login kembali.");

    String query = "?";
    if (keyword != null && keyword.trim().isNotEmpty) {
       String cleanKeyword = keyword.trim(); 
       // Smart Search: Angka -> NIM, Huruf -> Nama
       if (RegExp(r'^[0-9]+$').hasMatch(cleanKeyword)) {
         query += "nim=$cleanKeyword&";
       } else {
         query += "name=$cleanKeyword&";
       }
    }
    if (startDate != null) query += "start=$startDate&";
    if (endDate != null) query += "end=$endDate";

    final url = Uri.parse('${ApiConfig.baseUrl}/v1/admin/attendance/filter$query');
    
    // DEBUGGING URL
    print("Requesting: $url");

    final response = await http.get(
      url, 
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}
    );
    
    // DEBUGGING RESPONSE
    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => StudentListItemDTO.fromJson(e)).toList();
      } catch (e) {
        print("Error Parsing JSON: $e");
        return [];
      }
    } else {
      return [];
    }
  }

  // 2. Get Detail Summary
  Future<StudentSummaryDTO?> getStudentSummary(String nim) async {
    final token = await _getToken();
    if (token == null) throw Exception("Sesi habis.");

    final url = Uri.parse('${ApiConfig.baseUrl}/v1/admin/attendances/student/$nim');
    final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;

      final firstItem = data.first;
      // Handle Key Difference: Coba studentName, name, nama
      String name = (firstItem['studentName'] ?? firstItem['name'] ?? firstItem['nama'] ?? '-').toString();
      String studentNim = (firstItem['studentNim'] ?? firstItem['nim'] ?? nim).toString();
      
      int present = 0; int late = 0; int absent = 0;

      for (var item in data) {
        String status = (item['status'] ?? '').toString().toLowerCase();
        if (status == 'present') present++;
        else if (status == 'late') late++;
        else if (status == 'absent') absent++;
      }

      return StudentSummaryDTO(
        name: name, nim: studentNim, major: "-",
        presentCount: present, lateCount: late, absentCount: absent,
      );
    }
    return null;
  }


  Future<String?> downloadReport(String type, {String? keyword, String? startDate, String? endDate}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Sesi habis.");

      // Endpoint: PDF atau CSV
      String endpoint = type == 'pdf' ? "/v1/admin/export/pdf" : "/v1/admin/export/csv";
      
      String query = "?";
      if (keyword != null && keyword.trim().isNotEmpty) {
         String cleanKeyword = keyword.trim(); 
         if (RegExp(r'^[0-9]+$').hasMatch(cleanKeyword)) {
           query += "nim=$cleanKeyword&";
         } else {
           query += "name=$cleanKeyword&";
         }
      }
      if (startDate != null) query += "start=$startDate&";
      if (endDate != null) query += "end=$endDate";

      final fullUrl = "${ApiConfig.baseUrl}$endpoint$query";

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
        final ext = type == 'pdf' ? 'pdf' : 'csv'; 
        final fileName = "Admin_Report_$timestamp.$ext";

        // --------------------------------------------------------
        // LOGIKA WEB (Safe for Browser)
        // --------------------------------------------------------
        if (kIsWeb) {
          final List<int> bytes = List<int>.from(response.data);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          return "web_download_success"; 
        } 
        
        // --------------------------------------------------------
        // LOGIKA MOBILE (ANDROID/IOS)
        // --------------------------------------------------------
        else {
           // Kode ini HANYA jalan jika kIsWeb == false
           // Jadi aman dari MissingPluginException di browser
           
           final dir = await getApplicationDocumentsDirectory();
           final path = "${dir.path}/$fileName";
           
           // Simpan file
           io.File(path).writeAsBytesSync(response.data);
           
           return path;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Gagal download: $e");
    }
  }
}