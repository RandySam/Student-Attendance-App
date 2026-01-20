package com.example.appbinus.service;

import com.example.appbinus.dto.AdminLoginRequestDTO;
import com.example.appbinus.dto.AdminLoginResponseDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;
import com.example.appbinus.entity.Attendance;
import com.example.appbinus.entity.Student;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;



public interface AdminService
{
    AdminLoginResponseDTO adminLogin(AdminLoginRequestDTO requestDTO);
    List<StudentAttendanceDTO> getAllAttendances(LocalDate date);
    List<StudentAttendanceDTO> getAttendanceByStudentNim(String studentNim);
    Student findByStudentNim(String studentNim);
    List<Attendance> filterAttendance(String nim, String name, LocalDate start, LocalDate end);
    byte[] exportFilteredToPdf(String nim, String name, LocalDate start, LocalDate end);
    byte[] exportFilteredToCsv(String nim, String name, LocalDate start, LocalDate end);
    byte[] exportStudentToPdf(String nim);
    byte[] exportStudentToCsv(String nim);
}
