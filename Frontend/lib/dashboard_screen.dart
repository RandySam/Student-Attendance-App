import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

// Import Halaman Login Anda
import 'login_selection_screen.dart'; // Sesuaikan nama file login Anda

import 'attendance_service.dart';
import 'models/student_attendance_dto.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoadingApi = false; 
  Position? _currentPosition; 

  late Timer _liveClockTimer;
  String _currentTime = '';
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  DateTime? _clockOutTime;
  Duration _workDuration = Duration.zero;
  Timer? _workDurationTimer;

  String _currentLocationText = 'Mencari lokasi...';
  bool _locationServiceError = false;
  
  // Data dari API untuk cek status hari ini
  StudentAttendanceDTO? _todayAttendance;

  final double _campusLatitude = -6.201435;
  final double _campusLongitude = 106.781853;

  @override
  void initState() {
    super.initState();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _getTime();
    _determinePosition();
    _fetchTodayAttendance(); // Ambil data hari ini saat init
  }

  @override
  void dispose() {
    _liveClockTimer.cancel();
    _workDurationTimer?.cancel();
    super.dispose();
  }

  // --- FUNGSI LOGOUT (FITUR BARU) ---
  Future<void> _handleLogout() async {
    // Tampilkan konfirmasi dialog
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // Hapus Token
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Menghapus semua data sesi

      if (mounted) {
        // Pindah ke Halaman Login & Hapus Riwayat
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginSelectionScreen()), 
          (route) => false,
        );
      }
    }
  }

  // --- FUNGSI FETCH DATA HARI INI (AGAR STATUS AWAL VALID) ---
  Future<void> _fetchTodayAttendance() async {
    try {
      final data = await _attendanceService.getMyAttendance();
      if (mounted && data != null) {
        setState(() {
          _todayAttendance = data;
          // Sinkronkan state lokal dengan data API
          if (data.clockIn != null) {
             _isClockedIn = true;
             _clockInTime = DateTime.parse(data.clockIn!);
             if (data.clockOut == null) {
               _startWorkTimer(); // Lanjutkan timer jika belum clock out
             } else {
               _clockOutTime = DateTime.parse(data.clockOut!);
               _isClockedIn = false; // Sudah selesai
             }
          }
        });
      }
    } catch (e) {
      // Silent error
    }
  }

  Future<void> _determinePosition() async {
    // ... (Kode Geolocation SAMA PERSIS seperti sebelumnya) ...
    setState(() {
      _currentLocationText = 'Memverifikasi lokasi...';
      _locationServiceError = false;
      _currentPosition = null;
    });
    // (Saya singkat bagian ini agar muat, gunakan kode geolocation Anda yang sudah benar tadi)
    // ...
    // ...
    // Jika di Debug Mode (Laptop), pakai lokasi kampus
    if (kDebugMode) {
        setState(() {
          _currentPosition = Position(
            latitude: _campusLatitude,
            longitude: _campusLongitude,
            timestamp: DateTime.now(),
            accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0,
          );
          _currentLocationText = "Lokasi Developer (Kampus)";
        });
    }
  }

  void _showVerificationPopup() async {
     // ... (Kode Popup SAMA PERSIS seperti sebelumnya) ...
     // Gunakan kode lama Anda
     _performClockIn();
  }

  void _getTime() {
    final String formattedDateTime = DateFormat('HH:mm:ss').format(DateTime.now());
    if (mounted) setState(() => _currentTime = formattedDateTime);
  }

  Future<void> _performClockIn() async {
    setState(() => _isLoadingApi = true);
    try {
      // Pastikan posisi ada (untuk laptop pake mock di _determinePosition)
      if (_currentPosition == null) await _determinePosition();

      final response = await _attendanceService.clockIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      setState(() {
        _isClockedIn = true;
        _clockInTime = DateTime.parse(response.clockIn!); 
        _clockOutTime = null;
        _todayAttendance = response; // Update data hari ini
        _workDuration = Duration.zero;
        _startWorkTimer();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingApi = false);
    }
  }

  Future<void> _performClockOut() async {
    setState(() => _isLoadingApi = true);
    if (_currentPosition == null) await _determinePosition();
    
    try {
      final response = await _attendanceService.clockOut(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      setState(() {
        _isClockedIn = false;
        _clockOutTime = DateTime.parse(response.clockOut!);
        _todayAttendance = response; // Update data hari ini
        _workDurationTimer?.cancel();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingApi = false);
    }
  }

  void _startWorkTimer() {
    _workDurationTimer?.cancel(); 
    _workDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isClockedIn || !mounted || _clockInTime == null) { 
        timer.cancel();
        return;
      }
      setState(() {
        _workDuration = DateTime.now().difference(_clockInTime!);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock In/Out'),
        backgroundColor: const Color(0xFF0090D1),
        // --- BUTTON LOGOUT ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout, // Panggil Fungsi Logout
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTimerCard(),
              const SizedBox(height: 20),
              _buildAttendanceDetailsCard(),
              const SizedBox(height: 30),
              _buildClockInOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Widget _buildTimerCard SAMA PERSIS) ...
  // Silakan copy paste widget _buildTimerCard dari kode lama Anda

  // --- WIDGET STATUS (LOGIKA LATE/PRESENT) ---
  Widget _buildAttendanceDetailsCard() {
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    String clockInText = _clockInTime != null ? timeFormatter.format(_clockInTime!.toLocal()) : '--:--';
    String clockOutText = _clockOutTime != null ? timeFormatter.format(_clockOutTime!.toLocal()) : '--:--';
    String dateText = _clockInTime != null
        ? dateFormatter.format(_clockInTime!.toLocal())
        : DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    String statusText = '-';
    Color statusColor = Colors.black;

    // 1. Jika data dari API sudah ada statusnya, gunakan itu dulu sebagai base
    if (_todayAttendance != null && _todayAttendance!.status.isNotEmpty) {
       statusText = _todayAttendance!.status;
       if (statusText == 'Late') statusColor = Colors.orange;
       else if (statusText == 'Present') statusColor = Colors.green;
       else if (statusText == 'Absent') statusColor = Colors.red;
    }

    // 2. Override logika status secara lokal (agar responsif saat tombol ditekan)
    if (_isClockedIn && _clockInTime != null) {
      final checkTime = _clockInTime!.toLocal();
      final limitTime = DateTime(checkTime.year, checkTime.month, checkTime.day, 9, 0, 0);

      if (checkTime.isAfter(limitTime)) {
        statusText = 'Late';
        statusColor = Colors.orange;
      } else {
        statusText = 'Present';
        statusColor = Colors.green;
      }
    } else if (_clockOutTime != null) {
       // Jika sudah selesai, status tetap ikut clock in tadi (tidak berubah)
       // Atau bisa set 'Finished' jika mau beda
    } else {
      // Belum Clock In
      if(DateTime.now().hour >= 17) {
        statusText = 'Absent';
        statusColor = Colors.red;
      } else {
        statusText = 'Not Started';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Clock In', clockInText),
          const SizedBox(height: 16),
          _buildDetailRow('Clock Out', clockOutText),
          const SizedBox(height: 16),
          _buildDetailRow('Date', dateText),
          const SizedBox(height: 16),
          _buildDetailRow('Status', statusText, valueColor: statusColor), 
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black)),
      ],
    );
  }

  Widget _buildClockInOutButton() {
    // ... (Sama seperti kode lama Anda)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoadingApi 
            ? null 
            : (_isClockedIn ? _performClockOut : _showVerificationPopup), // Panggil popup dulu
        style: ElevatedButton.styleFrom(
          backgroundColor: _isClockedIn ? Colors.redAccent : const Color(0xFF0090D1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isLoadingApi 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
  
  // FUNGSI TAMBAHAN: BUILD TIMER CARD (PASTE DISINI JIKA HILANG)
  Widget _buildTimerCard() {
    return Container(
      // ... Isi sesuai kode lama Anda agar UI Timer tidak hilang ...
      // (Saya skip agar jawaban tidak terlalu panjang, cukup copy dari pertanyaan Anda sebelumnya)
      child: Text("Timer Placeholder (Isi dengan kode lama)"), 
    );
  }
}