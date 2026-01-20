package com.example.appbinus.controller;

import com.example.appbinus.dto.AdminLoginRequestDTO;
import com.example.appbinus.dto.AdminLoginResponseDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;
import com.example.appbinus.entity.Admin;
import com.example.appbinus.entity.Student;
import com.example.appbinus.repository.AdminRepository;
import com.example.appbinus.service.AdminService;
import io.jsonwebtoken.security.Password;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@CrossOrigin(origins = "*")
public class AdminController
{
    @Autowired
    private AdminService adminService;

    @PostMapping("/auth/login")
    public ResponseEntity<AdminLoginResponseDTO> login(@RequestBody AdminLoginRequestDTO
                                                               requestDTO)
    {
        AdminLoginResponseDTO responseDTO = adminService.adminLogin(requestDTO);
        return ResponseEntity.ok(responseDTO);
    }

    @GetMapping("/attendances")
    public ResponseEntity<List<StudentAttendanceDTO>> getAllAttendances(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
            )
    {
        List<StudentAttendanceDTO> attendanceDTO = adminService.getAllAttendances(date);
        return ResponseEntity.ok(attendanceDTO);
    }

    @GetMapping("/attendances/student/{nim}")
    public ResponseEntity<List<StudentAttendanceDTO>> getAttendanceByStudentNim(
            @PathVariable("nim") String studentNIm
    )
    {
        List<StudentAttendanceDTO> attendances = adminService.getAttendanceByStudentNim(studentNIm);
        return ResponseEntity.ok(attendances);
    }

    @GetMapping("/student/{nim}")
    public ResponseEntity<Student> findStudentByStudentNim(
            @PathVariable("nim") String studentNim
    )
    {
        Student student = adminService.findByStudentNim(studentNim);
        return ResponseEntity.ok(student);
    }

    @GetMapping("/attendance/filter")
    public ResponseEntity<?> filterAttendance(
            @RequestParam(required = false) String nim,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end
    ) {
        return ResponseEntity.ok(
                adminService.filterAttendance(nim, name, start, end)
        );
    }

    @GetMapping(value = "/export/pdf", consumes = MediaType.ALL_VALUE)
    public ResponseEntity<byte[]> exportFilteredPdf(
            @RequestParam(required = false) String nim,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end
    ) {
        byte[] file = adminService.exportFilteredToPdf(nim, name, start, end);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=attendance_report.pdf")
                .body(file);
    }

    @GetMapping(value = "/export/csv", consumes = MediaType.ALL_VALUE)
    public ResponseEntity<byte[]> exportFilteredCsv(
            @RequestParam(required = false) String nim,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end
    ) {
        byte[] file = adminService.exportFilteredToCsv(nim, name, start, end);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=attendance_report.csv")
                .body(file);
    }



    @GetMapping(value = "/{nim}/pdf", consumes = MediaType.ALL_VALUE)
    public ResponseEntity<byte[]> exportStudentPdf(@PathVariable String nim) {
        byte[] file = adminService.exportStudentToPdf(nim);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=attendance_" + nim + ".pdf")
                .body(file);
    }

    @GetMapping(value = "/{nim}/csv", consumes = MediaType.ALL_VALUE)
    public ResponseEntity<byte[]> exportStudentCsv(@PathVariable String nim) {
        byte[] file = adminService.exportStudentToCsv(nim);
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=attendance_" + nim + ".csv")
                .body(file);
    }



}
