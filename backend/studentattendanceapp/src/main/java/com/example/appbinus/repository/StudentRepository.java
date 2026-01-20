package com.example.appbinus.repository;

import com.example.appbinus.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;


@Repository
public interface StudentRepository extends JpaRepository<Student, String>
{
    Optional<Student> findByStudentEmailIgnoreCase(String studentEmail);
}
