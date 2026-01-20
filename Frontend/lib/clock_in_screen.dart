import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'attendance_service.dart';
import 'models/student_attendance_dto.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoadingApi = false; 
  Position? _currentPosition; 

  late Timer _liveClockTimer;
  String _currentTime = '';
  
  // --- STATE UTAMA ---
  bool _isClockedIn = false; // Sedang kerja?
  bool _isFinished = false;  // Sudah selesai hari ini? (Clock Out Done)
  
  DateTime? _clockInTime;
  DateTime? _clockOutTime;
  Duration _workDuration = Duration.zero;
  Timer? _workDurationTimer;

  String _currentLocationText = 'Mencari lokasi...';
  bool _locationServiceError = false;

  final double _campusLatitude = -6.201435;
  final double _campusLongitude = 106.781853;

  @override
  void initState() {
    super.initState();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _getTime();
    _determinePosition(); 
    _checkTodayStatus(); // Cek status saat init
  }

  @override
  void dispose() {
    _liveClockTimer.cancel();
    _workDurationTimer?.cancel();
    super.dispose();
  }

  // --- FUNGSI CEK STATUS HARI INI ---
  Future<void> _checkTodayStatus() async {
    try {
      final data = await _attendanceService.getMyAttendance();
      if (data != null && mounted) {
        setState(() {
          if (data.clockIn != null) {
            _clockInTime = DateTime.parse(data.clockIn!);
            _isClockedIn = true;
            
            if (data.clockOut != null) {
              // SUDAH CLOCK OUT -> SELESAI
              _clockOutTime = DateTime.parse(data.clockOut!);
              _isClockedIn = false;
              _isFinished = true; 
            } else {
              // MASIH KERJA -> LANJUT TIMER
              _startWorkTimer();
            }
          }
        });
      }
    } catch (e) {
      // Silent error (mungkin belum absen)
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _currentLocationText = 'Memverifikasi lokasi...';
      _locationServiceError = false;
      _currentPosition = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
       setState(() { _currentLocationText = 'Layanan lokasi mati.'; _locationServiceError = true; });
       return; 
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _currentLocationText = 'Izin lokasi ditolak.'; _locationServiceError = true; });
        return; 
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() { _currentLocationText = 'Izin lokasi ditolak selamanya.'; _locationServiceError = true; });
      return; 
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position; 
        _currentLocationText = placemarks.isNotEmpty
            ? '${placemarks[0].street}, ${placemarks[0].subLocality}'
            : 'Lokasi dikenali';
      });
    } catch (e) {
      if (kDebugMode) {
        print("--- DEV MODE: Menggunakan lokasi kampus. ---");
        setState(() {
          _currentPosition = Position(latitude: _campusLatitude, longitude: _campusLongitude, timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0);
          _currentLocationText = "Lokasi Developer (Kampus)";
          _locationServiceError = false; 
        });
      } else {
        setState(() { _currentLocationText = 'Gagal mendapatkan lokasi.'; _locationServiceError = true; });
      }
    }
  }

  void _showVerificationPopup() async {
    await _determinePosition();
    if (!mounted) return;

    if (_locationServiceError || _currentPosition == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error Lokasi'),
          content: Text(_currentLocationText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      );
      return; 
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Lokasi'),
        content: Text("Lokasi Anda: $_currentLocationText. Lanjutkan clock in?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performClockIn(); 
            },
            child: const Text('Konfirmasi Clock In'),
          ),
        ],
      ),
    );
  }

  void _getTime() {
    final String formattedDateTime = DateFormat('HH:mm:ss').format(DateTime.now());
    if (mounted) setState(() => _currentTime = formattedDateTime);
  }

  Future<void> _performClockIn() async {
    setState(() => _isLoadingApi = true);

    try {
      final response = await _attendanceService.clockIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _isClockedIn = true;
        _isFinished = false;
        _clockInTime = DateTime.parse(response.clockIn!); 
        _clockOutTime = null;
        _workDuration = Duration.zero;
        _startWorkTimer();
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingApi = false);
    }
  }

  Future<void> _performClockOut() async {
    setState(() => _isLoadingApi = true);

    await _determinePosition();
    if (_currentPosition == null && !kDebugMode) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mendapatkan lokasi."), backgroundColor: Colors.red));
       setState(() => _isLoadingApi = false);
       return;
    }

    try {
      final response = await _attendanceService.clockOut(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      setState(() {
        _isClockedIn = false;
        _isFinished = true; // TANDAI SELESAI
        _clockOutTime = DateTime.parse(response.clockOut!);
        _workDurationTimer?.cancel();
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
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
  title: const Text(
    'Clock In/Out',
    style: TextStyle(
      color: Colors.white,        // <-- TEKS PUTIH
      fontWeight: FontWeight.w600,
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,          // <-- ICON BACK PUTIH
  ),
  backgroundColor: const Color(0xFF0090D1),
  foregroundColor: Colors.white,  // <-- PENTING BIAR SEMUA TEKS PUTIH
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

  Widget _buildTimerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Lokasi', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded( 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                              _locationServiceError ? Icons.location_off : Icons.location_on,
                              color: _locationServiceError ? Colors.red : const Color(0xFF0090D1),
                              size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _currentLocationText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentTime,
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w600, color: Color(0xFF0090D1)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0090D1),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total work hours today', style: TextStyle(color: Colors.white, fontSize: 14)),
                Text(
                  _formatDuration(_workDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    // Logic Status
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
      statusText = 'Finished';
      statusColor = Colors.blue;
    } else {
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

  // --- PERUBAHAN TOMBOL CLOCK IN/OUT ---
  Widget _buildClockInOutButton() {
    
    String btnText = "Clock In";
    Color btnColor = const Color(0xFF0090D1);
    VoidCallback? btnAction = _showVerificationPopup;
    bool isDisabled = false;

    if (_isFinished) {
       btnText = "Selesai Hari Ini";
       btnColor = Colors.green;
       isDisabled = true;
       btnAction = null;
    } else if (_isClockedIn) {
       btnText = "Clock Out";
       btnColor = Colors.redAccent;
       btnAction = _performClockOut;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoadingApi || isDisabled) 
            ? null 
            : btnAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isLoadingApi 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                btnText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}