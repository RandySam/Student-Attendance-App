package com.example.appbinus.service.impl;

import com.example.appbinus.config.JwtUtil;
import com.example.appbinus.dto.AdminLoginRequestDTO;
import com.example.appbinus.dto.AdminLoginResponseDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;
import com.example.appbinus.entity.Admin;
import com.example.appbinus.entity.Attendance;
import com.example.appbinus.entity.Student;
import com.example.appbinus.repository.AdminRepository;
import com.example.appbinus.repository.AttendanceRepository;
import com.example.appbinus.repository.StudentRepository;
import com.example.appbinus.service.AdminService;
import com.lowagie.text.Document;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import jakarta.persistence.EntityNotFoundException;
import jakarta.persistence.criteria.JoinType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.hibernate.mapping.Join;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import jakarta.persistence.criteria.Predicate;

@Service
public class AdminServiceImpl implements AdminService
{
    @Autowired
    private AdminRepository adminRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;


    @Override
    public AdminLoginResponseDTO adminLogin(AdminLoginRequestDTO requestDTO)
    {
        Admin admin = adminRepository.findByAdminEmail(requestDTO.getEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));

        if(!passwordEncoder.matches(requestDTO.getPassword(), admin.getAdminPassword()))
        {
            throw new RuntimeException("Password salah woy");
        }

        String token = jwtUtil.generateToken(admin.getAdminEmail());

        return new AdminLoginResponseDTO(token, admin.getAdminName(), admin.getAdminEmail());
    }

    @Override
    public List<StudentAttendanceDTO> getAllAttendances(LocalDate date) {

        List<Attendance> attendances;

        if (date != null)
        {
            attendances = attendanceRepository.findByAttendanceDate(date);
        }
        else
        {
            attendances = attendanceRepository.findAll();
        }

        return attendances.stream()
                .map(attendance -> new StudentAttendanceDTO(
                        attendance.getStudent().getStudentNim(),
                        attendance.getStudent().getStudentName(),
                        attendance.getAttendanceDate(),
                        attendance.getClockIn(),
                        attendance.getClockOut(),
                        attendance.getStatus()
                ))
                .toList();
    }

    @Override
    public List<StudentAttendanceDTO> getAttendanceByStudentNim(String studentNim) {
        List<Attendance> attendances = attendanceRepository.findByStudent_StudentNimAndAttendanceDateBetween(
                studentNim,
                java.time.LocalDate.of(2000, 1, 1),
                java.time.LocalDate.now()
        );

        return attendances.stream()
                .map(attendance -> new StudentAttendanceDTO(
                        attendance.getStudent().getStudentNim(),
                        attendance.getStudent().getStudentName(),
                        attendance.getAttendanceDate(),
                        attendance.getClockIn(),
                        attendance.getClockOut(),
                        attendance.getStatus()
                ))
                .toList();
    }

    @Override
    public Student findByStudentNim(String studentNim) {
        return studentRepository.findById(studentNim)
                .orElseThrow(() -> new EntityNotFoundException(
                        "Mahasiswa dengan NIM " + studentNim + " tidak ditemukan"
                ));
    }

    @Override
    public List<Attendance> filterAttendance(String nim, String name, LocalDate start, LocalDate end) {
        return attendanceRepository.findAll((root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (nim != null && !nim.isEmpty()) {
                predicates.add(cb.like(root.get("student").get("studentNim"), "%" + nim + "%"));
            }

            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(cb.lower(root.get("student").get("studentName")),
                        "%" + name.toLowerCase() + "%"));
            }

            if (start != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("attendanceDate"), start));
            }

            if (end != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("attendanceDate"), end));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        });
    }


    @Override
    public byte[] exportFilteredToPdf(String nim, String name, LocalDate start, LocalDate end) {
        // Gunakan method filter yang sudah ada untuk ambil datanya
        List<Attendance> attendances = attendanceRepository.filterAttendance(nim, name, start, end);
        return generatePdf(attendances);
    }

    @Override
    public byte[] exportFilteredToCsv(String nim, String name, LocalDate start, LocalDate end) {
        List<Attendance> attendances = attendanceRepository.filterAttendance(nim, name, start, end);
        return generateCsv(attendances);
    }

    @Override
    public byte[] exportStudentToPdf(String nim) {
        Student student = studentRepository.findById(nim)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        List<Attendance> attendances =
                attendanceRepository.findByStudent_StudentNimAndAttendanceDateBetween(
                        nim, LocalDate.of(2000,1,1), LocalDate.now()
                );

        return generatePdf(attendances);
    }

    @Override
    public byte[] exportStudentToCsv(String nim) {
        Student student = studentRepository.findById(nim)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        List<Attendance> attendances =
                attendanceRepository.findByStudent_StudentNimAndAttendanceDateBetween(
                        nim, LocalDate.of(2000,1,1), LocalDate.now()
                );

        return generateCsv(attendances);
    }

    private byte[] generatePdf(List<Attendance> attendances) {
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();

            Document document = new Document();
            PdfWriter.getInstance(document, baos);

            document.open();

            document.add(new Paragraph("Attendance Report"));
            document.add(new Paragraph("Generated on: " + LocalDate.now()));
            document.add(new Paragraph("\n"));

            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);

            table.addCell("NIM");
            table.addCell("Name");
            table.addCell("Date");
            table.addCell("Clock In");
            table.addCell("Clock Out");
            table.addCell("Status");

            for (Attendance a : attendances) {
                table.addCell(a.getStudent().getStudentNim());
                table.addCell(a.getStudent().getStudentName());
                table.addCell(a.getAttendanceDate().toString());
                table.addCell(a.getClockIn() != null ? a.getClockIn().toString() : "-");
                table.addCell(a.getClockOut() != null ? a.getClockOut().toString() : "-");
                table.addCell(a.getStatus());
            }

            document.add(table);
            document.close();

            return baos.toByteArray();

        } catch (Exception e) {
            throw new RuntimeException("Error generating PDF", e);
        }
    }

    private byte[] generateCsv(List<Attendance> attendances) {
        try {
            StringBuilder sb = new StringBuilder();

            // Header CSV
            sb.append("NIM,Name,Date,Clock In,Clock Out,Status\n");

            for (Attendance a : attendances) {
                sb.append(a.getStudent().getStudentNim()).append(",");
                sb.append(safeCsv(a.getStudent().getStudentName())).append(",");
                sb.append(a.getAttendanceDate()).append(",");
                sb.append(a.getClockIn() != null ? a.getClockIn() : "-").append(",");
                sb.append(a.getClockOut() != null ? a.getClockOut() : "-").append(",");
                sb.append(safeCsv(a.getStatus()));
                sb.append("\r\n");
            }

            return sb.toString().getBytes("UTF-8");

        } catch (Exception e) {
            throw new RuntimeException("Error generating CSV", e);
        }
    }


    private String safeCsv(String value) {
        if (value == null) return "";
        String v = value.replace("\"", "\"\"");
        return "\"" + v + "\"";
    }

}
