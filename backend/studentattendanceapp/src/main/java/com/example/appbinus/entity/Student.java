package com.example.appbinus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Table(name = "student")
@NoArgsConstructor
@AllArgsConstructor
public class Student
{
    @Id
    private String studentNim;

    @Column(name = "email", nullable = false)
    private String studentEmail;

    @Column(name = "password", nullable = false)
    private String studentPassword;

    @Column(name = "name")
    private String studentName;

    @Column(name = "major")
    private String studentMajor;

    @Column(name = "telephone")
    private String studentTelephone;

    @Column(name = "address")
    private String studentAddress;

    private boolean verified = false;

}
