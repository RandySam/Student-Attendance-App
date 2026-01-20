package com.example.appbinus.service;

import com.example.appbinus.dto.*;

public interface StudentService
{
    StudentResponseDTO register(StudentRegisterRequestDTO requestDTO);
    StudentResponseDTO verifyOtp(OtpVerificationRequestDTO requestDTO);
    StudentLoginResponseDTO login (StudentLoginRequestDTO requestDTO);
    StudentResponseDTO resendOtp(ResendOtpRequestDTO requestDTO);
    StudentProfileDTO getProfile(String studentNim);
    StudentProfileDTO updateProfile(String studentNim, StudentProfileUpdateDTO request);
    StudentResponseDTO forgotPassword(ForgotPasswordRequestDTO request);
    StudentResponseDTO verifyForgotPasswordOtp(ForgotPasswordVerifyDTO request);
    StudentResponseDTO resetPassword(ResetPasswordRequestDTO request);
    byte[] exportToPdf(String studentNim);
    byte[] exportToCsv(String studentNim);
}
