package com.example.appbinus.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceRequestDTO
{
    private String studentNim;
    private double latitude;
    private double longitude;
}
