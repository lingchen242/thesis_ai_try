package com.example.thesis;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * 毕业论文管理系统启动类。
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@MapperScan("com.example.thesis.mapper")
public class ThesisApplication {

    public static void main(String[] args) {
        SpringApplication.run(ThesisApplication.class, args);
    }
}
