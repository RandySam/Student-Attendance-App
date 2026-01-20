package com.example.appbinus.service;

import com.example.appbinus.dto.AttendanceRequestDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;

import java.util.List;

public interface AttendanceService
{
    StudentAttendanceDTO clockIn(AttendanceRequestDTO requestDTO);
    StudentAttendanceDTO clockOut(AttendanceRequestDTO requestDTO);
    List<StudentAttendanceDTO> getMyAttendance(String studentNim);
}
