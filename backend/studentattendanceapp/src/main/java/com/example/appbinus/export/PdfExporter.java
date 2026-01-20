package com.example.appbinus.export;

import com.example.appbinus.entity.Attendance;
import com.lowagie.text.*;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;

import java.io.ByteArrayOutputStream;
import java.util.List;

public class PdfExporter {

    public static byte[] export(List<Attendance> attendances, String studentNim) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document document = new Document(PageSize.A4);

            PdfWriter.getInstance(document, out);
            document.open();

            Font titleFont = new Font(Font.HELVETICA, 16, Font.BOLD);
            Font normalFont = new Font(Font.HELVETICA, 12);

            Paragraph title = new Paragraph("Laporan Kehadiran Mahasiswa", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);

            document.add(new Paragraph("NIM: " + studentNim, normalFont));
            document.add(new Paragraph("Total: " + attendances.size() + " data", normalFont));
            document.add(Chunk.NEWLINE);

            PdfPTable table = new PdfPTable(4);
            table.setWidthPercentage(100);

            addTableHeader(table);

            for (Attendance a : attendances) {
                table.addCell(String.valueOf(a.getAttendanceDate()));
                table.addCell(a.getClockIn() != null ? a.getClockIn().toString() : "-");
                table.addCell(a.getClockOut() != null ? a.getClockOut().toString() : "-");
                table.addCell(a.getStatus());
            }

            document.add(table);
            document.close();

            return out.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Gagal membuat PDF: " + e.getMessage());
        }
    }

    private static void addTableHeader(PdfPTable table) {
        PdfPCell cell = new PdfPCell();
        cell.setPhrase(new Phrase("Tanggal"));
        table.addCell(cell);

        cell.setPhrase(new Phrase("Clock In"));
        table.addCell(cell);

        cell.setPhrase(new Phrase("Clock Out"));
        table.addCell(cell);

        cell.setPhrase(new Phrase("Status"));
        table.addCell(cell);
    }
}
