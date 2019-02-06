package com.itersive.tutorial.controller;

import com.itersive.tutorial.model.request.SingupDTO;
import com.itersive.tutorial.common.model.Role;
import com.itersive.tutorial.common.model.RoleName;
import com.itersive.tutorial.common.model.User;
import com.itersive.tutorial.common.repository.RoleRepository;
import com.itersive.tutorial.common.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashSet;
import java.util.Set;

@RestController
public class UserController {

    private UserRepository userRepository;
    private RoleRepository roleRepository;
    private PasswordEncoder passwordEncoder;

    public UserController(UserRepository userRepository, RoleRepository roleRepository, PasswordEncoder encoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = encoder;
    }

    @GetMapping("/user")
    @PreAuthorize("hasRole('ADMIN')")
    public Iterable<User> getAllUsers() {
        return userRepository.findAll();
    }

    @PostMapping("/user")
    public ResponseEntity<String> createUser(@RequestBody SingupDTO singupDTO) {
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

    @GetMapping(value = "/user", params = "id")
    @PreAuthorize("#id == principal.id")
    public User getUserById(@RequestParam Long id) {
        return userRepository.findById(id).get();
    }

    @GetMapping("/user/{Id}")
    @PreAuthorize("#id == principal.id")
    public User getUserById2(@PathVariable("Id") Long id) {
        return userRepository.findById(id).get();
    }

    @DeleteMapping("/user")
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteUserById(@RequestParam Long id) {
        userRepository.deleteById(id);
    }
}
