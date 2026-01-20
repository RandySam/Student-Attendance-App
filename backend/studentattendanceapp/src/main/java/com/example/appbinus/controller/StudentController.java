package com.example.appbinus.controller;

import com.example.appbinus.config.JwtUtil;
import com.example.appbinus.dto.*;
import com.example.appbinus.entity.Student;
import com.example.appbinus.repository.StudentRepository;
import com.example.appbinus.service.StudentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/student")
@CrossOrigin(origins = "*")
public class StudentController
{
    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private StudentService studentService;

    @Autowired
    private JwtUtil jwt;

    private String extractStudentNim(String token) {
        return jwt.extractUsername(token);
    }

    @PostMapping("/register")
    public StudentResponseDTO register(@RequestBody StudentRegisterRequestDTO requestDTO) {
        return studentService.register(requestDTO);
    }

    @PostMapping("/verify-otp")
    public StudentResponseDTO verifyOtp(@RequestBody OtpVerificationRequestDTO requestDTO) {
        return studentService.verifyOtp(requestDTO);
    }

    @PostMapping("/login")
    public StudentLoginResponseDTO login(@RequestBody StudentLoginRequestDTO requestDTO) {
        return studentService.login(requestDTO);
    }

    @PostMapping("/resend-otp")
    public StudentResponseDTO resendOtp(@RequestBody ResendOtpRequestDTO requestDTO) {
        return studentService.resendOtp(requestDTO);
    }

    @GetMapping("/profile")
    public StudentProfileDTO getProfile(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        String nim = extractStudentNim(token);

        return studentService.getProfile(nim);
    }

    @PutMapping("/profile")
    public StudentProfileDTO updateProfile(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody StudentProfileUpdateDTO request
    ) {
        String token = authHeader.replace("Bearer ", "");
        String nim = extractStudentNim(token);

        return studentService.updateProfile(nim, request);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<StudentResponseDTO> forgotPassword(@RequestBody ForgotPasswordRequestDTO req) {
        return ResponseEntity.ok(studentService.forgotPassword(req));
    }

    @PostMapping("/verify-forgot-otp")
    public ResponseEntity<StudentResponseDTO> verifyForgotOtp(@RequestBody ForgotPasswordVerifyDTO req) {
        return ResponseEntity.ok(studentService.verifyForgotPasswordOtp(req));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<StudentResponseDTO> resetPassword(@RequestBody ResetPasswordRequestDTO req) {
        return ResponseEntity.ok(studentService.resetPassword(req));
    }


    @GetMapping("/export/pdf/{studentNim}")
    public ResponseEntity<byte[]> exportPdf(
            @RequestHeader("Authorization") String token,
            @PathVariable String studentNim
    ) {
        byte[] file = studentService.exportToPdf(studentNim); // Langsung pakai NIM

        return ResponseEntity.ok()
                .header("Content-Type", "application/pdf")
                .header("Content-Disposition", "attachment; filename=attendance" + studentNim + ".pdf")
                .body(file);
    }

    @GetMapping(value = "/export/csv/{studentNim}", produces = "text/csv;charset=UTF-8")
    public ResponseEntity<byte[]> exportCsv(
            @RequestHeader("Authorization") String token,
            @PathVariable String studentNim
    ) {
        Student student = studentRepository.findById(studentNim)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        byte[] file = studentService.exportToCsv(studentNim);

        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=attendance.csv")
                .header("Content-Type", "text/csv; charset=utf-8")
                .header("X-Content-Type-Options", "nosniff")
                .body(file);
    }

}
