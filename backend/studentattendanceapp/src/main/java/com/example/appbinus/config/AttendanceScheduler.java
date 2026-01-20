package com.example.appbinus.config;

import com.example.appbinus.entity.Attendance;
import com.example.appbinus.entity.Student;
import com.example.appbinus.repository.AttendanceRepository;
import com.example.appbinus.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.*;
import java.util.List;

@Component
@RequiredArgsConstructor
public class AttendanceScheduler {

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    // Menandai Alfa setiap hari kerja pukul 10:00
    @Scheduled(cron = "0 0 10 * * MON-FRI", zone = "Asia/Jakarta")
    public void markAbsentStudents() {
        LocalDate today = LocalDate.now();

        List<Student> students = studentRepository.findAll();

        for (Student student : students) {
            boolean alreadyClockedIn = attendanceRepository
                    .findByStudent_StudentNimAndAttendanceDate(student.getStudentNim(), today)
                    .stream()
                    .anyMatch(a -> a.getClockIn() != null);

            if (!alreadyClockedIn) {
                Attendance attendance = new Attendance();
                attendance.setStudent(student);
                attendance.setAttendanceDate(today);
                attendance.setStatus("Absent");
                attendanceRepository.save(attendance);
            }
        }

        System.out.println("✅ Auto-mark Absent selesai untuk tanggal " + today);
    }
}