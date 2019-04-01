package com.itersive.tutorial.controller;

import com.itersive.tutorial.message.request.SingupDTO;
import com.itersive.tutorial.model.Role;
import com.itersive.tutorial.model.RoleName;
import com.itersive.tutorial.model.User;
import com.itersive.tutorial.repository.RoleRepository;
import com.itersive.tutorial.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashSet;
import java.util.Set;

@RestController
public class RegistrationController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @PostMapping("/signup")
    public ResponseEntity<String> registerUser(@RequestBody SingupDTO singupDTO) {
        if (userRepository.existsByUsername(singupDTO.getUsername())) {
            return new ResponseEntity<>("Username already used", HttpStatus.BAD_REQUEST);
        }
        if (userRepository.existsByEmail(singupDTO.getEmail())) {
            return new ResponseEntity<>("Email already used", HttpStatus.BAD_REQUEST);
        }

        User user = new User(singupDTO.getUsername(), singupDTO.getEmail(),
                passwordEncoder.encode(singupDTO.getPassword()));

        Set<Role> roles = new HashSet<>();

        singupDTO.getRoles().forEach(role -> {
            switch (role) {
                case "admin" :
                    Role adminRole = roleRepository.findByName(RoleName.ROLE_ADMIN)
                            .orElseThrow(() -> new RuntimeException("Admin role not found"));
                    roles.add(adminRole);
                    break;
                case "user" :
                    Role userRole = roleRepository.findByName(RoleName.ROLE_USER)
                            .orElseThrow(() -> new RuntimeException("User role not found"));
                    roles.add(userRole);
                    break;
                case "dba" :
                    Role dbaRole = roleRepository.findByName(RoleName.ROLE_DBA)
                            .orElseThrow(() -> new RuntimeException("DBA role not found"));
                    roles.add(dbaRole);
                    break;
            }
        });

        user.setRoles(roles);
        userRepository.save(user);

        return ResponseEntity.ok("User registered.");
    }
}
