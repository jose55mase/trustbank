package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeHasSupervisorsException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.AssignmentTypeNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.DuplicateAssignmentTypeException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IAssignmentTypeDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ISupervisorAssignmentDao;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeRequest;
import com.bolsadeideas.springboot.backend.apirest.models.dto.AssignmentTypeResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.AssignmentTypeEntity;

/**
 * Implementación del servicio de gestión de Tipos de Asignación.
 * Maneja operaciones CRUD con validaciones de nombre único y protección contra eliminación
 * de tipos con supervisores asociados.
 */
@Service
public class AssignmentTypeServiceImpl implements IAssignmentTypeService {

    @Autowired
    private IAssignmentTypeDao assignmentTypeDao;

    @Autowired
    private ISupervisorAssignmentDao supervisorAssignmentDao;

    @Override
    @Transactional(readOnly = true)
    public List<AssignmentTypeResponse> findAll() {
        List<AssignmentTypeEntity> types = assignmentTypeDao.findAll();
        return types.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<AssignmentTypeResponse> findActive() {
        List<AssignmentTypeEntity> types = assignmentTypeDao.findByActiveTrue();
        return types.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentTypeResponse findById(Long id) {
        AssignmentTypeEntity entity = assignmentTypeDao.findById(id)
                .orElseThrow(() -> new AssignmentTypeNotFoundException(id));
        return toResponse(entity);
    }

    @Override
    @Transactional
    public AssignmentTypeResponse create(AssignmentTypeRequest request) {
        // Validar nombre único
        if (assignmentTypeDao.existsByName(request.getName())) {
            throw new DuplicateAssignmentTypeException();
        }

        AssignmentTypeEntity entity = new AssignmentTypeEntity();
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        entity.setActive(request.getActive() != null ? request.getActive() : true);
        entity.setFilterValue(request.getFilterValue());

        AssignmentTypeEntity saved = assignmentTypeDao.save(entity);
        return toResponse(saved);
    }

    @Override
    @Transactional
    public AssignmentTypeResponse update(Long id, AssignmentTypeRequest request) {
        AssignmentTypeEntity entity = assignmentTypeDao.findById(id)
                .orElseThrow(() -> new AssignmentTypeNotFoundException(id));

        // Validar nombre único (excluyendo el actual)
        Optional<AssignmentTypeEntity> existing = assignmentTypeDao.findByName(request.getName());
        if (existing.isPresent() && !existing.get().getId().equals(id)) {
            throw new DuplicateAssignmentTypeException();
        }

        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        if (request.getActive() != null) {
            entity.setActive(request.getActive());
        }
        entity.setFilterValue(request.getFilterValue());

        AssignmentTypeEntity saved = assignmentTypeDao.save(entity);
        return toResponse(saved);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        AssignmentTypeEntity entity = assignmentTypeDao.findById(id)
                .orElseThrow(() -> new AssignmentTypeNotFoundException(id));

        // Verificar supervisores asociados
        Long supervisorCount = supervisorAssignmentDao.countByAssignmentTypeId(id);
        if (supervisorCount > 0) {
            throw new AssignmentTypeHasSupervisorsException(supervisorCount);
        }

        assignmentTypeDao.delete(entity);
    }

    /**
     * Convierte un AssignmentTypeEntity a AssignmentTypeResponse DTO, incluyendo conteo de supervisores.
     */
    private AssignmentTypeResponse toResponse(AssignmentTypeEntity entity) {
        Long count = supervisorAssignmentDao.countByAssignmentTypeId(entity.getId());
        return new AssignmentTypeResponse(
                entity.getId(),
                entity.getName(),
                entity.getDescription(),
                entity.getActive(),
                entity.getFilterValue(),
                count != null ? count.intValue() : 0,
                entity.getCreatedAt()
        );
    }
}
