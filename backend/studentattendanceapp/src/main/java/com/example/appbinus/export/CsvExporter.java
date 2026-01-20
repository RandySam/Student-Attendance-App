package com.example.appbinus.export;

import com.example.appbinus.entity.Attendance;
import java.nio.charset.StandardCharsets;
import java.util.List;

public class CsvExporter {

    public static byte[] export(List<Attendance> attendances, String studentNim) {
        try {
            StringBuilder sb = new StringBuilder();

            // HEADER
            sb.append("Tanggal,Clock In,Clock Out,Status\n");

            // DATA ROWS
            for (Attendance a : attendances) {
                sb.append(a.getAttendanceDate().toString()).append(",");
                sb.append(a.getClockIn() != null ? a.getClockIn().toString() : "-").append(",");
                sb.append(a.getClockOut() != null ? a.getClockOut().toString() : "-").append(",");
                sb.append(a.getStatus()).append("\n");
            }

            // Convert ke byte[]
            return sb.toString().getBytes(StandardCharsets.UTF_8);

        } catch (Exception e) {
            throw new RuntimeException("Gagal membuat CSV: " + e.getMessage());
        }
    }
}
