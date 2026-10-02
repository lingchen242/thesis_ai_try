package com.example.thesis.controller;

import com.example.thesis.common.PageResult;
import com.example.thesis.common.R;
import com.example.thesis.dto.PageQuery;
import com.example.thesis.dto.Requests;
import com.example.thesis.entity.Student;
import com.example.thesis.entity.SysUser;
import com.example.thesis.entity.Teacher;
import com.example.thesis.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 基础数据接口：账号 / 教师 / 学生。仅管理员可写。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // ======================================================= 账号
    @GetMapping("/users")
    public R<PageResult<SysUser>> pageUsers(PageQuery query,
                                            @RequestParam(required = false) String role) {
        return R.ok(userService.pageUsers(query, role));
    }

    @PostMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysUser> createUser(@RequestBody SysUser user,
                                 @RequestParam(required = false) String password) {
        return R.ok(userService.createUser(user, password));
    }

    @PutMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<SysUser> updateUser(@PathVariable Long id, @RequestBody SysUser user) {
        user.setId(id);
        return R.ok(userService.updateUser(user));
    }

    @DeleteMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return R.ok();
    }

    @PutMapping("/users/{id}/password")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> resetPassword(@PathVariable Long id,
                                 @RequestBody(required = false) Requests.ResetPassword req) {
        userService.resetPassword(id, req == null ? null : req.password());
        return R.ok();
    }

    // ======================================================= 教师
    @GetMapping("/teachers")
    public R<PageResult<Teacher>> pageTeachers(PageQuery query,
                                               @RequestParam(required = false) String college,
                                               @RequestParam(required = false) String teacherType,
                                               @RequestParam(required = false) Integer canReview) {
        return R.ok(userService.pageTeachers(query, college, teacherType, canReview));
    }

    @PostMapping("/teachers")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Teacher> createTeacher(@RequestBody Teacher teacher,
                                    @RequestParam(required = false) String password) {
        return R.ok(userService.saveTeacher(teacher, password));
    }

    @PutMapping("/teachers/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Teacher> updateTeacher(@PathVariable Long id, @RequestBody Teacher teacher) {
        teacher.setId(id);
        return R.ok(userService.saveTeacher(teacher, null));
    }

    @DeleteMapping("/teachers/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> deleteTeacher(@PathVariable Long id) {
        userService.deleteTeacher(id);
        return R.ok();
    }

    /** 指导 / 评阅教师下拉选项 */
    @GetMapping("/teachers/options")
    public R<Map<String, List<Teacher>>> teacherOptions() {
        Map<String, List<Teacher>> map = new LinkedHashMap<>();
        map.put("advisors", userService.advisorOptions());
        map.put("reviewers", userService.reviewerOptions());
        return R.ok(map);
    }

    // ======================================================= 学生
    @GetMapping("/students")
    public R<PageResult<Student>> pageStudents(PageQuery query,
                                               @RequestParam(required = false) String grade,
                                               @RequestParam(required = false) String college,
                                               @RequestParam(required = false) String major,
                                               @RequestParam(required = false) Long advisorId) {
        return R.ok(userService.pageStudents(query, grade, college, major, advisorId));
    }

    @PostMapping("/students")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Student> createStudent(@RequestBody Student student,
                                    @RequestParam(required = false) String password) {
        return R.ok(userService.saveStudent(student, password));
    }

    @PutMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Student> updateStudent(@PathVariable Long id, @RequestBody Student student) {
        student.setId(id);
        return R.ok(userService.saveStudent(student, null));
    }

    @DeleteMapping("/students/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public R<Void> deleteStudent(@PathVariable Long id) {
        userService.deleteStudent(id);
        return R.ok();
    }
}
