package com.example.appbinus.service.impl;

import com.example.appbinus.config.JwtUtil;
import com.example.appbinus.dto.*;
import com.example.appbinus.entity.Attendance;
import com.example.appbinus.entity.Student;
import com.example.appbinus.export.PdfExporter;
import com.example.appbinus.repository.AttendanceRepository;
import com.example.appbinus.repository.StudentRepository;
import com.example.appbinus.service.StudentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.Charset;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class StudentServiceImpl implements StudentService
{
    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private EmailServiceImpl emailService;

    @Autowired
    private JwtUtil jwtUtil;


    private record OtpEntry(String otp, Instant expiresAt, String type){}

    private static final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();

    private String generateOtp()
    {
        Random random = new Random();
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }

    private void saveOtp(String email, String otp, String purpose) {
        otpStore.put(email, new OtpEntry(
                otp,
                Instant.now().plusSeconds(300),
                purpose
        ));
    }

    @Override
    public StudentResponseDTO register(StudentRegisterRequestDTO requestDTO) {
        if (studentRepository.findByStudentEmailIgnoreCase(requestDTO.getEmail()).isPresent()) {
            throw new RuntimeException("Email sudah terdaftar");
        }

        Student student = new Student();
        student.setStudentName(requestDTO.getName());
        student.setStudentNim(requestDTO.getNim());
        student.setStudentEmail(requestDTO.getEmail());
        student.setStudentPassword(passwordEncoder.encode(requestDTO.getPassword()));
        student.setVerified(false);

        studentRepository.save(student);

        // Generate OTP
        String otp = generateOtp();
        saveOtp(requestDTO.getEmail(), otp, "REGISTER");

        // Kirim via email (bukan console)
        emailService.sendOtpEmail(requestDTO.getEmail(), otp);

        return new StudentResponseDTO(true, "OTP berhasil terkirim");
    }

    @Override
    public StudentResponseDTO verifyOtp(OtpVerificationRequestDTO requestDTO) {
        Student student = studentRepository.findByStudentEmailIgnoreCase(requestDTO.getStudentEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));

        OtpEntry otpEntry = otpStore.get(requestDTO.getStudentEmail());
        if (otpEntry == null) {
            throw new RuntimeException("OTP tidak ditemukan atau sudah kadaluarsa.");
        }

        if (Instant.now().isAfter(otpEntry.expiresAt())) {
            otpStore.remove(requestDTO.getStudentNim());
            throw new RuntimeException("OTP sudah kadaluarsa. Silakan registrasi ulang.");
        }

        if (!otpEntry.otp.equals(requestDTO.getOtpCode())) {
            throw new RuntimeException("OTP salah.");
        }

        student.setVerified(true);
        studentRepository.save(student);
        otpStore.remove(requestDTO.getStudentEmail());

        return new StudentResponseDTO(true, "Verifikasi berhasil. Akun Anda telah aktif.");
    }

    @Override
    public StudentLoginResponseDTO login(StudentLoginRequestDTO requestDTO) {
        Student student = studentRepository.findByStudentEmailIgnoreCase(requestDTO.getStudentEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));

        if (!student.isVerified()) {
            throw new RuntimeException("Akun belum diverifikasi.");
        }

        if (!passwordEncoder.matches(requestDTO.getStudentPassword(), student.getStudentPassword())) {
            throw new RuntimeException("Password salah.");
        }

        String token = jwtUtil.generateToken(student.getStudentNim());


        return new StudentLoginResponseDTO(token, student.getStudentEmail());
    }

    @Override
    public StudentResponseDTO resendOtp(ResendOtpRequestDTO requestDTO) {
        Student student = studentRepository.findByStudentEmailIgnoreCase(requestDTO.getStudentEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));

        if (student.isVerified()) {
            throw new RuntimeException("Akun sudah diverifikasi.");
        }

        String otp = generateOtp();
        saveOtp(requestDTO.getStudentEmail(), otp, "REGISTER");
        
        emailService.sendOtpEmail(student.getStudentEmail(), otp);

        return new StudentResponseDTO(true, "OTP baru telah dikirim ke email Anda.");
    }

    @Override
    public StudentProfileDTO getProfile(String studentNim) {
        Student student = studentRepository.findById(studentNim)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        return new StudentProfileDTO(
                student.getStudentNim(),
                student.getStudentName(),
                student.getStudentEmail(),
                student.getStudentTelephone(),
                student.getStudentAddress(),
                student.getStudentMajor()
        );
    }

    @Override
    public StudentProfileDTO updateProfile(String studentNim, StudentProfileUpdateDTO request) {
        Student student = studentRepository.findById(studentNim)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        student.setStudentTelephone(request.getStudentTelephone());
        student.setStudentAddress(request.getStudentAddress());
        student.setStudentMajor(request.getStudentMajor());

        Student updated = studentRepository.save(student);

        return new StudentProfileDTO(
                updated.getStudentNim(),
                updated.getStudentName(),
                updated.getStudentEmail(),
                updated.getStudentTelephone(),
                updated.getStudentAddress(),
                updated.getStudentMajor()
        );
    }

    @Override
    public StudentResponseDTO forgotPassword(ForgotPasswordRequestDTO request) {

        System.out.println("FORGOT PW REQUEST EMAIL = [" + request.getEmail() + "]");
        System.out.println("EMAIL TRIM = [" + request.getEmail().trim() + "]");
        System.out.println("DB HAS = " + studentRepository.findAll().stream()
                .map(Student::getStudentEmail)
                .toList()
        );
        Student student = studentRepository.findByStudentEmailIgnoreCase(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));


        String otp = generateOtp();
        otpStore.put(
                request.getEmail(),
                new OtpEntry(otp, Instant.now().plusSeconds(300), "RESET_PASSWORD")
        );

        emailService.sendOtpEmail(request.getEmail(), otp);

        return new StudentResponseDTO(true, "OTP reset password telah dikirim ke email Anda.");
    }


    @Override
    public StudentResponseDTO verifyForgotPasswordOtp(ForgotPasswordVerifyDTO request) {
        OtpEntry entry = otpStore.get(request.getEmail());

        if (entry == null || !"RESET_PASSWORD".equals(entry.type())) {
            throw new RuntimeException("OTP tidak ditemukan atau salah.");
        }

        if (Instant.now().isAfter(entry.expiresAt())) {
            otpStore.remove(request.getEmail());
            throw new RuntimeException("OTP sudah kadaluarsa.");
        }

        if (!entry.otp().equals(request.getOtp())) {
            throw new RuntimeException("OTP salah.");
        }

        return new StudentResponseDTO(true, "OTP benar. Anda dapat mengganti password.");
    }

    @Override
    public StudentResponseDTO resetPassword(ResetPasswordRequestDTO request) {

        Student student = studentRepository.findByStudentEmailIgnoreCase(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email tidak ditemukan"));

        OtpEntry entry = otpStore.get(request.getEmail());

        if (entry == null || !"RESET_PASSWORD".equals(entry.type())) {
            throw new RuntimeException("OTP tidak valid untuk reset password.");
        }

        student.setStudentPassword(passwordEncoder.encode(request.getNewPassword()));
        studentRepository.save(student);

        otpStore.remove(request.getEmail());

        return new StudentResponseDTO(true, "Password berhasil direset.");
    }


    @Override
    public byte[] exportToPdf(String studentNim) {
        List<Attendance> attendances = attendanceRepository.findByStudent_StudentNim(studentNim);

        return PdfExporter.export(attendances, studentNim);
    }

    @Override
    public byte[] exportToCsv(String studentNim) {
        List<Attendance> attendances = attendanceRepository.findByStudent_StudentNimAndAttendanceDateBetween(
                studentNim,
                LocalDate.of(2000, 1, 1),
                LocalDate.now()
        );

        return generateCsv(attendances);
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

            return sb.toString().getBytes(Charset.forName("UTF-8"));
        } catch (Exception e) {
            throw new RuntimeException("Error generating CSV", e);
        }
    }

    private String safeCsv(String value) {
        if (value == null) return "";
        // Escape tanda kutip dua jika ada
        String v = value.replace("\"", "\"\"");
        return "\"" + v + "\"";
    }
}
