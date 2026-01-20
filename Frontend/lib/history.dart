import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

// Import Service dan Model
import '../student_service.dart'; // Sesuaikan path
import '../models/student_attendance_dto.dart';

class HistoryStudentScreen extends StatefulWidget {
  const HistoryStudentScreen({super.key});

  @override
  State<HistoryStudentScreen> createState() => _HistoryStudentScreenState();
}

class _HistoryStudentScreenState extends State<HistoryStudentScreen> {
  final StudentService _attendanceService = StudentService();

  // --- STATE DATA ---
  bool _isLoading = true;
  bool _isDownloading = false;

  List<StudentAttendanceDTO> _allData = [];
  List<StudentAttendanceDTO> _filteredData = [];

  // --- FILTER ---
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  Map<String, int> _summary = {'Present': 0, 'Late': 0, 'Absent': 0};

  // Warna & Logo
  static const Color primaryColor = Color(0xFF007BFF);
  static const Color pageBackground = Color(0xFFF5F7FB);
  static const String appLogoPath = 'assets/images/Binus_Attendance.png';

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  // --- 1. FETCH DATA DARI API ---
  Future<void> _fetchHistoryData() async {
    try {
      final data = await _attendanceService.getHistory();

      if (mounted) {
        setState(() {
          _allData = data;
          _filteredData = data;
          _calculateSummary();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. LOGIKA SUMMARY ---
void _calculateSummary() {
  int present = 0;
  int late = 0;
  int absent = 0;

  for (var item in _filteredData) {
    final status = item.status.toLowerCase();
    if (status == 'present') {
      present++;
    } else if (status == 'late' || status == 'telat') {
      late++;
    } else if (status == 'absent' || status == 'alpha' || status == 'alfa') {
      // <-- ALFA dihitung ke Absent, BUKAN Late
      absent++;
    }
  }

  setState(() {
    _summary = {'Present': present, 'Late': late, 'Absent': absent};
  });
}


  // --- 3. LOGIKA FILTER ---
  void _filterData() {
    setState(() {
      _filteredData = _allData.where((item) {
        DateTime itemDate;
        try {
          itemDate = DateTime.parse(item.attendanceDate);
        } catch (e) {
          return false;
        }

        bool matchesDate = true;
        if (_selectedFromDate != null) {
          matchesDate = matchesDate &&
              (itemDate.isAtSameMomentAs(_selectedFromDate!) ||
                  itemDate.isAfter(_selectedFromDate!));
        }
        if (_selectedToDate != null) {
          matchesDate = matchesDate &&
              itemDate.isBefore(_selectedToDate!.add(const Duration(days: 1)));
        }
        return matchesDate;
      }).toList();

      _calculateSummary();
    });
  }

  void _resetFilter() {
    setState(() {
      _fromDateController.clear();
      _toDateController.clear();
      _selectedFromDate = null;
      _selectedToDate = null;
      _filteredData = _allData;
      _calculateSummary();
    });
    Navigator.of(context).pop();
  }

  // --- 4. DOWNLOAD EXPORT (WEB & MOBILE SUPPORT) ---
  Future<void> _handleDownload(String type) async {
    setState(() => _isDownloading = true);
    try {
      String? result = await _attendanceService.exportAttendance(type);

      if (result != null) {
        if (result == "Success Web Download" || result.contains("Success")) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Download dimulai... Cek folder Downloads / browser."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await OpenFilex.open(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File dibuka"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Download PDF"),
              onTap: () {
                Navigator.pop(c);
                _handleDownload('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Download Excel / CSV"),
              onTap: () {
                Navigator.pop(c);
                _handleDownload('excel');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, bool isFromDate, Function stfSetState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      stfSetState(() {
        final txt = DateFormat('dd MMM yyyy').format(picked);
        if (isFromDate) {
          _selectedFromDate = picked;
          _fromDateController.text = txt;
        } else {
          _selectedToDate = picked;
          _toDateController.text = txt;
        }
      });
    }
  }

  Future<void> _showFilterDialog() async {
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Filter Riwayat",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fromDateController,
                readOnly: true,
                onTap: () => _selectDate(ctx, true, ss),
                decoration: const InputDecoration(
                  labelText: "Dari",
                  prefixIcon: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _toDateController,
                readOnly: true,
                onTap: () => _selectDate(ctx, false, ss),
                decoration: const InputDecoration(
                  labelText: "Sampai",
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _resetFilter,
              child: const Text(
                "Reset",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _filterData();
                Navigator.pop(c);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text("Terapkan"),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. BUILD UI ---

  static Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 13 : 12,
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    if (_filteredData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            "Tidak ada riwayat absensi.",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey.shade300),
            outside: BorderSide.none,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.3),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2F5),
              ),
              children: [
                _buildTableCell('Clock In', isHeader: true),
                _buildTableCell('Clock Out', isHeader: true),
                _buildTableCell('Tanggal', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            ..._filteredData.map((dto) {
              Color statusColor;
              final st = dto.status.toLowerCase();

              if (st == 'present') {
                statusColor = Colors.green;
              } else if (st == 'late' || st == 'telat') {
                statusColor = Colors.orange;
              } else if (st == 'absent' || st == 'alfa' || st == 'alpha') {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.black;
              }

              String dateDisplay = dto.attendanceDate;
              try {
                DateTime dt = DateTime.parse(dto.attendanceDate);
                dateDisplay = DateFormat('dd MMM yyyy').format(dt);
              } catch (_) {}

              String formatTime(String? time) {
                if (time == null || time.isEmpty || time == '-') return "-";
                try {
                  DateTime dt = DateTime.parse(time).toLocal();
                  return DateFormat('HH:mm').format(dt);
                } catch (e) {
                  return time;
                }
              }

              return TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  _buildTableCell(formatTime(dto.clockIn)),
                  _buildTableCell(formatTime(dto.clockOut)),
                  _buildTableCell(dateDisplay),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        dto.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summItem('Absent', _summary['Absent'] ?? 0, Colors.red),
          _summItem('Late', _summary['Late'] ?? 0, Colors.orange),
          _summItem('Present', _summary['Present'] ?? 0, Colors.green),
        ],
      ),
    );
  }

  Widget _summItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90.0),
        child: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          automaticallyImplyLeading: false,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                appLogoPath,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHistoryData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Riwayat Kehadiran Anda",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pantau riwayat Clock In / Out dan status kehadiran.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black12,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _isDownloading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : TextButton.icon(
                                        onPressed: _showDownloadOptions,
                                        icon: const Icon(
                                          Icons.download,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Download Report',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                OutlinedButton.icon(
                                  onPressed: _showFilterDialog,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(Icons.filter_list, size: 18),
                                  label: const Text('Filter'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildHistoryTable(),
                            const SizedBox(height: 20),
                            _buildSummaryCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
