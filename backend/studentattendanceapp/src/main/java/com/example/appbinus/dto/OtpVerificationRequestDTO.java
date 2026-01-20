package com.example.appbinus.dto;

import lombok.Data;

@Data
public class OtpVerificationRequestDTO
{
    private String studentNim;
    private String studentEmail;
    private String otpCode;
}
