package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bolsadeideas.springboot.backend.apirest.exceptions.ForbiddenOperationException;
import com.bolsadeideas.springboot.backend.apirest.exceptions.ResourceNotFoundException;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadCommentDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;

/**
 * Implementación del servicio de gestión de comentarios de Leads.
 * Maneja la creación, edición y eliminación de comentarios con validación de autoría.
 */
@Service
public class LeadCommentServiceImpl implements ILeadCommentService {

    @Autowired
    private ILeadCommentDao leadCommentDao;

    @Autowired
    private ILeadDao leadDao;

    @Autowired
    private IUserDao userDao;

    @Override
    @Transactional(readOnly = true)
    public List<LeadCommentEntity> findByLeadId(Long leadId) {
        return leadCommentDao.findByLeadIdOrderByCreatedAtDesc(leadId);
    }

    @Override
    @Transactional
    public LeadCommentEntity create(Long leadId, Long userId, String text) {
        // Validate lead exists
        leadDao.findById(leadId).orElseThrow(
                () -> new ResourceNotFoundException("lead", leadId));

        // Get user reference
        UserEntity user = userDao.findById(userId).orElseThrow(
                () -> new ResourceNotFoundException("usuario", userId));

        // Create and persist comment
        LeadCommentEntity comment = new LeadCommentEntity();
        comment.setLeadId(leadId);
        comment.setUser(user);
        comment.setText(text);

        return leadCommentDao.save(comment);
    }

    @Override
    @Transactional
    public LeadCommentEntity update(Long commentId, Long userId, String text) {
        // Fetch comment or throw 404
        LeadCommentEntity comment = leadCommentDao.findById(commentId).orElseThrow(
                () -> new ResourceNotFoundException("comentario", commentId));

        // Validate ownership
        if (!comment.getUser().getId().equals(userId)) {
            throw new ForbiddenOperationException("No tienes permiso para editar este comentario");
        }

        // Update text and set editedAt timestamp
        comment.setText(text);
        comment.setEditedAt(new Date());

        return leadCommentDao.save(comment);
    }

    @Override
    @Transactional
    public void delete(Long commentId, Long userId) {
        // Fetch comment or throw 404
        LeadCommentEntity comment = leadCommentDao.findById(commentId).orElseThrow(
                () -> new ResourceNotFoundException("comentario", commentId));

        // Validate ownership
        if (!comment.getUser().getId().equals(userId)) {
            throw new ForbiddenOperationException("No tienes permiso para eliminar este comentario");
        }

        // Remove from DB
        leadCommentDao.delete(comment);
    }
}
