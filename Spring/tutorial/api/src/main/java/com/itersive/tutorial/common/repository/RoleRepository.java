package com.itersive.tutorial.common.repository;

import com.itersive.tutorial.common.model.Role;
import com.itersive.tutorial.common.model.RoleName;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RoleRepository extends CrudRepository<Role, Long> {
    Optional<Role> findByName(RoleName name);
}
