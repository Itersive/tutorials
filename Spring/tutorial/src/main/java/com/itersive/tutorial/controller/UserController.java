package com.itersive.tutorial.controller;

import com.itersive.tutorial.model.User;
import com.itersive.tutorial.repository.UserRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    private UserRepository repository;

    public UserController(UserRepository r) {
        this.repository = r;
    }

    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public Iterable<User> getAllUsers() {
        return repository.findAll();
    }

    @PostMapping("/user")
    public void createUser(@RequestParam String name, @RequestParam String email) {
        User u = new User();
        u.setEmail(email);
        u.setUsername(name);

        repository.save(u);
    }

    @GetMapping("/user")
    @PreAuthorize("hasRole('USER')")
    public User getUserById(@RequestParam Long id) {
        return repository.findById(id).get();
    }

    @GetMapping("/user/{Id}")
    @PreAuthorize("hasRole('USER')")
    public User getUserById2(@PathVariable("Id") Long id) {
        return repository.findById(id).get();
    }

    @DeleteMapping("/user")
    public void deleteUserById(@RequestParam Long id) {
        repository.deleteById(id);
    }
}
