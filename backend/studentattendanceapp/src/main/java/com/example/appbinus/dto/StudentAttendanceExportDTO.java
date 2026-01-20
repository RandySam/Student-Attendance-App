package com.example.appbinus.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class StudentAttendanceExportDTO
{
    private String date;
    private String clockIn;
    private String clockOut;
    private String status;
}
