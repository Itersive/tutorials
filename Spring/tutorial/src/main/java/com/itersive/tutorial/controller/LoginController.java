package com.itersive.tutorial.controller;

import com.itersive.tutorial.configuration.jwt.JwtProvider;
import com.itersive.tutorial.message.request.LoginDTO;
import com.itersive.tutorial.message.response.JwtTokenDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LoginController {
    @Autowired
    JwtProvider provider;
    @Autowired
    AuthenticationManager manager;

    @GetMapping("/token")
    public ResponseEntity authenticateUser(@RequestBody LoginDTO loginDTO) {
        Authentication authentication = manager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginDTO.getUsername(),
                        loginDTO.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = provider.genereteToken(authentication);

        return ResponseEntity.ok(new JwtTokenDTO(token));
    }
}
