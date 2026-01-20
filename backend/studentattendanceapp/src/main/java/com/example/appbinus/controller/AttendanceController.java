package com.example.appbinus.controller;

import com.example.appbinus.dto.AttendanceRequestDTO;
import com.example.appbinus.dto.StudentAttendanceDTO;
import com.example.appbinus.service.AttendanceService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/student/attendance")
@CrossOrigin(origins = "*")
public class AttendanceController
{
    @Autowired
    private AttendanceService attendanceService;

    @PostMapping("/clock-in")
    public StudentAttendanceDTO clockIn(@RequestBody AttendanceRequestDTO requestDTO) {
        System.out.println("DTO = " + requestDTO);
        return attendanceService.clockIn(requestDTO);
    }

    @PostMapping("/clock-out")
    public StudentAttendanceDTO clockOut(@RequestBody AttendanceRequestDTO requestDTO) {
        return attendanceService.clockOut(requestDTO);
    }

    @GetMapping("/history/{studentNim}")
    public List<StudentAttendanceDTO> getAttendanceHistory(@PathVariable String studentNim) {
        return attendanceService.getMyAttendance(studentNim);
    }
}
