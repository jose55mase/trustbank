package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentAlreadyExistsException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.NoAssignmentConfiguredException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IAssignmentTypeDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ISupervisorAssignmentDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.SupervisorAssignmentResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.AssignmentTypeEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.SupervisorAssignmentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ISupervisorAssignmentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SupervisorAssignmentServiceImpl implements ISupervisorAssignmentService {

    private static final Logger logger = LoggerFactory.getLogger(SupervisorAssignmentServiceImpl.class);

    @Autowired
    private ISupervisorAssignmentDao supervisorAssignmentDao;

    @Autowired
    private IAssignmentTypeDao assignmentTypeDao;

    @Autowired
    private IUserDao userDao;

    @Override
    @Transactional(readOnly = true)
    public List<SupervisorAssignmentResponse> findAll() {
        List<SupervisorAssignmentEntity> assignments = supervisorAssignmentDao.findAll();
        return assignments.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public SupervisorAssignmentResponse findByUserId(Long userId) {
        SupervisorAssignmentEntity assignment = supervisorAssignmentDao.findByUserId(userId)
                .orElseThrow(() -> new NoAssignmentConfiguredException(userId));
        return toResponse(assignment);
    }

    @Override
    @Transactional
    public SupervisorAssignmentResponse create(SupervisorAssignmentRequest request) {
        // Validar que el usuario no tenga asignación previa
        if (supervisorAssignmentDao.existsByUserId(request.getUserId())) {
            throw new AssignmentAlreadyExistsException(request.getUserId());
        }

        // Validar que el tipo de asignación existe
        AssignmentTypeEntity assignmentType = assignmentTypeDao.findById(request.getAssignmentTypeId())
                .orElseThrow(() -> new AssignmentTypeNotFoundException(request.getAssignmentTypeId()));

        // Obtener el usuario
        UserEntity user = userDao.findByid(request.getUserId());
        if (user == null) {
            throw new RuntimeException("USER_NOT_FOUND");
        }

        // Crear la asignación
        SupervisorAssignmentEntity assignment = new SupervisorAssignmentEntity();
        assignment.setUser(user);
        assignment.setAssignmentType(assignmentType);

        SupervisorAssignmentEntity saved = supervisorAssignmentDao.save(assignment);
        return toResponse(saved);
    }

    @Override
    @Transactional
    public SupervisorAssignmentResponse updateAssignment(Long userId, Long newAssignmentTypeId) {
        // Obtener la asignación existente
        SupervisorAssignmentEntity assignment = supervisorAssignmentDao.findByUserId(userId)
                .orElseThrow(() -> new NoAssignmentConfiguredException(userId));

        // Validar que el nuevo tipo de asignación existe
        AssignmentTypeEntity newAssignmentType = assignmentTypeDao.findById(newAssignmentTypeId)
                .orElseThrow(() -> new AssignmentTypeNotFoundException(newAssignmentTypeId));

        Long oldTypeId = assignment.getAssignmentType().getId();

        // Actualizar la asignación
        assignment.setAssignmentType(newAssignmentType);
        SupervisorAssignmentEntity saved = supervisorAssignmentDao.save(assignment);

        logger.info("Assignment changed: userId={}, oldTypeId={}, newTypeId={}", userId, oldTypeId, newAssignmentTypeId);

        return toResponse(saved);
    }

    @Override
    @Transactional
    public void deleteByUserId(Long userId) {
        if (!supervisorAssignmentDao.existsByUserId(userId)) {
            // Si no tiene asignación, no hay nada que eliminar (operación idempotente)
            return;
        }

        supervisorAssignmentDao.deleteByUserId(userId);
        logger.info("Assignment removed: userId={}, reason=ROLE_CHANGED", userId);
    }

    /**
     * Convierte un SupervisorAssignmentEntity a SupervisorAssignmentResponse DTO.
     */
    private SupervisorAssignmentResponse toResponse(SupervisorAssignmentEntity entity) {
        UserEntity user = entity.getUser();
        AssignmentTypeEntity type = entity.getAssignmentType();

        return new SupervisorAssignmentResponse(
                entity.getId(),
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                type.getId(),
                type.getName(),
                entity.getAssignedAt()
        );
    }
}
