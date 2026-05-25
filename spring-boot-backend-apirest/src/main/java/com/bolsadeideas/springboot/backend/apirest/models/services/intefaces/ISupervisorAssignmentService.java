package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentResponse;

import java.util.List;

public interface ISupervisorAssignmentService {

    List<SupervisorAssignmentResponse> findAll();

    SupervisorAssignmentResponse findByUserId(Long userId);

    SupervisorAssignmentResponse create(SupervisorAssignmentRequest request);

    SupervisorAssignmentResponse updateAssignment(Long userId, Long newAssignmentTypeId);

    void deleteByUserId(Long userId);
}
