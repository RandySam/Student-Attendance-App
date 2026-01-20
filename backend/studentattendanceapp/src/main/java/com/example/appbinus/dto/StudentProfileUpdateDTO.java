package com.example.appbinus.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class StudentProfileUpdateDTO
{
    private String studentTelephone;
    private String studentAddress;
    private String studentMajor;
}
