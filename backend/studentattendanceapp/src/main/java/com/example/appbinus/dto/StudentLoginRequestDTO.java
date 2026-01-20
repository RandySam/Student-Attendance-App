package com.example.appbinus.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class StudentLoginRequestDTO
{
    private String studentEmail;
    private String studentPassword;
}
