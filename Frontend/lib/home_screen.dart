import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'clock_in_screen.dart'; // Pastikan path benar

import '../student_service.dart';
import '../models/student_attendance_dto.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudentService _studentService = StudentService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  Map<DateTime, String> _attendanceData = {};

  int _presentCount = 0;
  int _lateCount = 0;
  int _absentCount = 0;

  static const Color primaryColor = Color(0xFF0077D8);
  static const Color pageBackground = Color(0xFFF5F7FB);

  // PNG logo aplikasi (sama seperti di screen lain)
  static const String appLogoPath = 'assets/images/Binus_Attendance.png';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
  try {
    List<StudentAttendanceDTO> history = await _studentService.getHistory();

    if (mounted) {
      setState(() {
        _attendanceData = {
          for (var item in history) _parseDate(item.attendanceDate): item.status
        };

        // ====== PERHITUNGAN SUMMARY YANG BENAR ======
        _presentCount = history.where((i) {
          final s = i.status.toLowerCase();
          return s == 'present';
        }).length;

        _lateCount = history.where((i) {
          final s = i.status.toLowerCase();
          return s == 'late' || s == 'telat';
        }).length;

        _absentCount = history.where((i) {
          final s = i.status.toLowerCase();
          // 'alfa' dari backend dianggap Absent
          return s == 'absent' || s == 'alfa' || s == 'alpha';
        }).length;
        // ============================================

        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  DateTime _parseDate(String dateStr) {
    try {
      DateTime dt = DateFormat("yyyy-MM-dd").parse(dateStr);
      return DateTime.utc(dt.year, dt.month, dt.day);
    } catch (e) {
      return DateTime.utc(1900, 1, 1);
    }
  }

  Color _getMarkerColor(String? status) {
    if (status == null) return Colors.transparent;
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(90.0), // <-- tinggikan AppBar sedikit
  child: AppBar(
    backgroundColor: primaryColor,
    elevation: 0,
    centerTitle: false,
    titleSpacing: 16,
    automaticallyImplyLeading: false,
    title: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LOGO PNG — diperbesar
        Image.asset(
          appLogoPath,
          height: 56,            // <--- ukuran logo diperbesar di sini
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Icon(
            Icons.school,
            color: Colors.white,
            size: 56,            // ikon fallback juga ikut besar
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: SizedBox(),     // tetap kosong, hanya untuk dorong konten ke kiri
        ),
      ],
    ),
  ),
),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAttendanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section judul tanggal
                    Text(
                      "Today, ${DateFormat('EEE, dd MMM yyyy').format(DateTime.now())}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildCalendar(),
                    const SizedBox(height: 24),

                    // Tombol Clock In / Out
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClockInScreen(),
                            ),
                          ).then((_) => _fetchAttendanceData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Clock In / Out',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Latest history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildHistoryRow('Present', _presentCount, Colors.green),
                    const SizedBox(height: 12),
                    _buildHistoryRow('Late', _lateCount, Colors.orange),
                    const SizedBox(height: 12),
                    _buildHistoryRow('Absent', _absentCount, Colors.red),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left),
          rightChevronIcon: Icon(Icons.chevron_right),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            final dateKey = DateTime.utc(day.year, day.month, day.day);
            final status = _attendanceData[dateKey];

            if (status != null) {
              return Positioned(
                bottom: 5,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _getMarkerColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color(0x550077D8),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
