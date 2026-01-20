import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

// Import Service & Model
import '../service/admin_service.dart'; // Pastikan path ini benar
import '../models/admin_models.dart'; 

class HistoryAdminScreen extends StatefulWidget {
  const HistoryAdminScreen({super.key});

  @override
  State<HistoryAdminScreen> createState() => _HistoryAdminScreenState();
}

class _HistoryAdminScreenState extends State<HistoryAdminScreen> {
  // Gunakan AdminService
  final AdminService _adminService = AdminService();

  List<StudentListItemDTO> _students = [];
  bool _isLoading = false;

  String? _filterKeyword;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // ====================================================================
  // A. FUNGSI API (FETCH & DOWNLOAD)
  // ====================================================================

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    String? startStr = _filterStartDate != null ? DateFormat('yyyy-MM-dd').format(_filterStartDate!) : null;
    String? endStr = _filterEndDate != null ? DateFormat('yyyy-MM-dd').format(_filterEndDate!) : null;

    try {
      final data = await _adminService.searchStudents(
        keyword: _filterKeyword,
        startDate: startStr,
        endDate: endStr,
      );
      if (mounted) {
        setState(() {
          _students = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownload() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text("Download PDF"),
            onTap: () { Navigator.pop(ctx); _processDownload('pdf'); },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text("Download Excel"),
            onTap: () { Navigator.pop(ctx); _processDownload('excel'); },
          ),
        ],
      ),
    );
  }

  Future<void> _processDownload(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sedang memproses download...")));
    
    String? startStr = _filterStartDate != null ? DateFormat('yyyy-MM-dd').format(_filterStartDate!) : null;
    String? endStr = _filterEndDate != null ? DateFormat('yyyy-MM-dd').format(_filterEndDate!) : null;

    try {
      final path = await _adminService.downloadReport(type, keyword: _filterKeyword, startDate: startStr, endDate: endStr);
      
      if (path != null) {
        // Jika path berisi string khusus Web
        if (path.contains("web_download_success")) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil diunduh! Cek folder Downloads browser."), backgroundColor: Colors.green));
        } else {
           // Jika Mobile, buka file
           await OpenFilex.open(path);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  // ====================================================================
  // B. MODAL FILTER (DENGAN TOMBOL RESET)
  // ====================================================================
  void _showFilterDialog() {
    final keywordController = TextEditingController(text: _filterKeyword);
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd = _filterEndDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Filter Data", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nama/NIM", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: keywordController,
                    decoration: InputDecoration(
                      hintText: "Cari mahasiswa...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text("Dari Tanggal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  _buildDatePickerField(tempStart, (picked) {
                    setStateDialog(() => tempStart = picked);
                  }),
                  
                  const SizedBox(height: 16),
                  
                  const Text("Hingga Tanggal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  _buildDatePickerField(tempEnd, (picked) {
                    setStateDialog(() => tempEnd = picked);
                  }),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                // TOMBOL RESET
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      keywordController.clear();
                      tempStart = null;
                      tempEnd = null;
                    });
                  },
                  child: const Text("Reset", style: TextStyle(color: Colors.red)),
                ),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterKeyword = keywordController.text;
                      _filterStartDate = tempStart;
                      _filterEndDate = tempEnd;
                    });
                    Navigator.pop(context);
                    _fetchStudents(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0090D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Cari", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerField(DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date != null ? DateFormat('dd MMM yyyy').format(date) : "Pilih Tanggal"),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // C. MODAL DETAIL STATISTIK
  // ====================================================================
  Future<void> _showDetailModal(String nim) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    final detail = await _adminService.getStudentSummary(nim);
    
    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    if (detail != null) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem("Nama", detail.name),
                const SizedBox(height: 10),
                _buildDetailItem("NIM", detail.nim),
                const SizedBox(height: 10),
                _buildDetailItem("Jurusan", detail.major),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Absent", detail.absentCount, Colors.red),
                      _buildStatItem("Late", detail.lateCount, Colors.orange),
                      _buildStatItem("Present", detail.presentCount, Colors.green),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text("$count", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ====================================================================
  // D. BUILD METHOD
  // ====================================================================
  @override
@override
@override
Widget build(BuildContext context) {
  return Container(
    color: const Color(0xFFF5F7FB),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          children: [
            // ===== HEADER BIRU =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF00B4FF),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Riwayat Kehadiran",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none, // hilangkan garis
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Pantau absensi mahasiswa secara real-time",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      decoration: TextDecoration.none, // hilangkan garis
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== CARD FILTER SAJA (TANPA SEARCH) =====
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showFilterDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0090D1), // box biru
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.filter_list, size: 20),
                    label: const Text(
                      "Filter Data",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== CARD TABEL DATA (TIDAK DIUBAH LOGIC-NYA) =====
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Header tabel
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE9ECEF),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Nama",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "NIM",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Status",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Isi tabel
                          Expanded(
                            child: _students.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Data tidak ditemukan",
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _students.length,
                                    separatorBuilder: (c, i) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final student = _students[index];

                                      Color statusColor = Colors.black;
                                      final stLower =
                                          student.status.toLowerCase();
                                      if (stLower == 'present') {
                                        statusColor = Colors.green;
                                      } else if (stLower == 'late' ||
                                          stLower == 'telat') {
                                        statusColor = Colors.orange;
                                      } else if (stLower == 'absent') {
                                        statusColor = Colors.red;
                                      }

                                      return InkWell(
                                        onTap: () =>
                                            _showDetailModal(student.nim),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      student.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      student.date,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  student.nim,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "In: ${student.clockIn}",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      student.status,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Footer: tombol download
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _handleDownload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0090D1),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Download Report",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
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