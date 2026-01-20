package com.example.appbinus.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentAttendanceDTO
{
    private String studentNim;
    private String studentName;
    private LocalDate attendanceDate;
    private LocalDateTime clockIn;
    private LocalDateTime clockOut;
    private String status;
}
