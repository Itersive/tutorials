package com.itersive.tutorial.service;

import com.itersive.tutorial.model.User;
import com.itersive.tutorial.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import javax.transaction.Transactional;

@Service
public class TutorialUserDetailsService implements UserDetailsService {

    private UserRepository userRepository;

    public TutorialUserDetailsService(UserRepository repo) {
        userRepository = repo;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        return TutorialUser.build(user);
    }
}
