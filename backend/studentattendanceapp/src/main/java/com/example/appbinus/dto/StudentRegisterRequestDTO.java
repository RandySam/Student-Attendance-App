package com.example.appbinus.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudentRegisterRequestDTO
{
    private  String name;
    private String email;
    private String nim;
    private String password;
}
