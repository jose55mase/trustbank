package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import org.springframework.data.repository.CrudRepository;

public interface RolDao extends CrudRepository<RolEntity, Long> {

}
