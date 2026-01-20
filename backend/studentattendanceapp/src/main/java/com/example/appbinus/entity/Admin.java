package com.example.appbinus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Table(name = "admin")
@NoArgsConstructor
@AllArgsConstructor
public class Admin
{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long adminId;

    @Column(name = "name")
    private String adminName;

    @Column(name = "email", nullable = false)
    private String adminEmail;

    @Column(name = "password", nullable = false)
    private String adminPassword;
}
