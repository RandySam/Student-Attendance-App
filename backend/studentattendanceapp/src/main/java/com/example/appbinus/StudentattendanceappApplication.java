package com.example.appbinus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class StudentattendanceappApplication {
	public static void main(String[] args) {
		SpringApplication.run(StudentattendanceappApplication.class, args);
	}

}
