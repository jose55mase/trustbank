package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IDocumentDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.DocumentEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IDocumentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DocumentServiceImpl implements IDocumentService {

    @Autowired
    private IDocumentDao documentDao;

    @Override
    @Transactional
    public DocumentEntity save(DocumentEntity document) {
        return documentDao.save(document);
    }

    @Override
    @Transactional(readOnly = true)
    public DocumentEntity findById(Long id) {
        return documentDao.findById(id).orElse(null);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DocumentEntity> findByUserId(Long userId) {
        return documentDao.findByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DocumentEntity> findPendingDocuments() {
        return documentDao.findPendingDocuments();
    }

    @Override
    @Transactional(readOnly = true)
    public List<DocumentEntity> findByStatus(String status) {
        return documentDao.findByStatus(status);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        documentDao.deleteById(id);
    }
}