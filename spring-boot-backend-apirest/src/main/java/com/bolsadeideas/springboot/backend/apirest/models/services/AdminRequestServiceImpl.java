package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IAdminRequestDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IAdminRequestService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AdminRequestServiceImpl implements IAdminRequestService {

    @Autowired
    private IAdminRequestDao adminRequestDao;

    @Override
    @Transactional
    public AdminRequestEntity save(AdminRequestEntity request) {
        return adminRequestDao.save(request);
    }

    @Override
    @Transactional(readOnly = true)
    public AdminRequestEntity findById(Long id) {
        return adminRequestDao.findById(id).orElse(null);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminRequestEntity> findAll() {
        return adminRequestDao.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminRequestEntity> findByUserId(Long userId) {
        return adminRequestDao.findByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminRequestEntity> findPendingRequests() {
        return adminRequestDao.findPendingRequests();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminRequestEntity> findByStatus(String status) {
        return adminRequestDao.findByStatus(status);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminRequestEntity> findByRequestType(String requestType) {
        return adminRequestDao.findByRequestType(requestType);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        adminRequestDao.deleteById(id);
    }
}