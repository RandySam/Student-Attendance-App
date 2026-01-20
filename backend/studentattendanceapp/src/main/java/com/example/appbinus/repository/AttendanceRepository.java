package com.example.appbinus.repository;

import com.example.appbinus.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;

import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;


@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long>, JpaSpecificationExecutor<Attendance>
{
    List<Attendance> findByStudent_StudentNimAndAttendanceDate(String studentNim, LocalDate attendanceDate);
    List<Attendance> findByAttendanceDate(LocalDate attendanceDate);
    List<Attendance> findByStudent_StudentNimAndAttendanceDateBetween(String studentNim, LocalDate start, LocalDate end);
    List<Attendance> findByStudent_StudentNim(String nim);
    @Query("""
    SELECT a FROM Attendance a
    JOIN FETCH a.student s
    WHERE
        (COALESCE(:nim, '') = '' OR s.studentNim LIKE CONCAT('%', :nim, '%'))
        AND (COALESCE(:name, '') = '' OR LOWER(s.studentName) LIKE CONCAT('%', LOWER(:name), '%'))
        AND (COALESCE(:start, a.attendanceDate) <= a.attendanceDate)
        AND (COALESCE(:end, a.attendanceDate) >= a.attendanceDate)
    """)

    List<Attendance> filterAttendance(@Param("nim") String nim,
                                      @Param("name") String name,
                                      @Param("start") LocalDate start,
                                      @Param("end") LocalDate end);


}
