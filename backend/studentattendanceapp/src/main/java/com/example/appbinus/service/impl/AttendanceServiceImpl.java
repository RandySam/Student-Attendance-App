package com.example.appbinus.service.impl;

import com.example.appbinus.dto.AttendanceRequestDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;
import com.example.appbinus.entity.Attendance;
import com.example.appbinus.entity.Student;
import com.example.appbinus.repository.AttendanceRepository;
import com.example.appbinus.repository.StudentRepository;
import com.example.appbinus.service.AttendanceService;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.List;

@Service
public class AttendanceServiceImpl implements AttendanceService {

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private StudentRepository studentRepository;


    private static final double CAMPUS_LATITUDE = -6.21966;
    private static final double CAMPUS_LONGITUDE = 106.9998183;
    private static final double MAX_RADIUS_METERS = 100.0;

    @Override
    public StudentAttendanceDTO clockIn(AttendanceRequestDTO requestDTO) {
        Student student = studentRepository.findById(requestDTO.getStudentNim())
                .orElseThrow(() -> new EntityNotFoundException("Mahasiswa tidak ditemukan"));

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        boolean alreadyClockedIn = attendanceRepository
                .findByStudent_StudentNimAndAttendanceDate(student.getStudentNim(), today)
                .stream()
                .anyMatch(a -> a.getClockIn() != null);

        if (alreadyClockedIn) {
            throw new RuntimeException("Kamu sudah clock in hari ini");
        }

        double distance = calculateDistanceMeters(
                CAMPUS_LATITUDE, CAMPUS_LONGITUDE,
                requestDTO.getLatitude(), requestDTO.getLongitude()
        );

        if (distance > MAX_RADIUS_METERS) {
            throw new RuntimeException("Kamu berada di luar area kampus");
        }


        String status = now.isAfter(LocalTime.of(9, 0)) ? "Late" : "Present";

        Attendance attendance = new Attendance();
        attendance.setStudent(student);
        attendance.setAttendanceDate(today);
        attendance.setClockIn(LocalDateTime.now());
        attendance.setStatus(status);

        attendanceRepository.save(attendance);


        return new StudentAttendanceDTO(
                student.getStudentNim(),
                student.getStudentName(),
                today,
                attendance.getClockIn(),
                null,
                status
        );
    }

    @Override
    public StudentAttendanceDTO clockOut(AttendanceRequestDTO requestDTO) {
        Student student = studentRepository.findById(requestDTO.getStudentNim())
                .orElseThrow(() -> new EntityNotFoundException("Mahasiswa tidak ditemukan"));

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();


        Attendance attendance = attendanceRepository
                .findByStudent_StudentNimAndAttendanceDate(student.getStudentNim(), today)
                .stream()
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Kamu belum clock in hari ini"));

        // Validasi waktu
        if (now.isBefore(LocalTime.of(17, 0))) {
            throw new RuntimeException("Belum bisa clock out sebelum jam 17:00");
        }

        attendance.setClockOut(LocalDateTime.now());
        attendanceRepository.save(attendance);

        return new StudentAttendanceDTO(
                student.getStudentNim(),
                student.getStudentName(),
                today,
                attendance.getClockIn(),
                attendance.getClockOut(),
                attendance.getStatus()
        );
    }

    @Override
    public List<StudentAttendanceDTO> getMyAttendance(String studentNim) {
        List<Attendance> attendances = attendanceRepository.findByStudent_StudentNimAndAttendanceDateBetween(
                studentNim,
                LocalDate.of(2000, 1, 1),
                LocalDate.now()
        );

        return attendances.stream()
                .map(a -> new StudentAttendanceDTO(
                        a.getStudent().getStudentNim(),
                        a.getStudent().getStudentName(),
                        a.getAttendanceDate(),
                        a.getClockIn(),
                        a.getClockOut(),
                        a.getStatus()
                ))
                .toList();
    }

    // Rumus Haversine — menghitung jarak antar dua koordinat (meter)
    private double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // radius bumi dalam meter
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
