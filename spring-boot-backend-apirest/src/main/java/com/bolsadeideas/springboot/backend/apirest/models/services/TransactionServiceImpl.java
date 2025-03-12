package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IUTransactionDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ITransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TransactionServiceImpl implements ITransactionService {

    @Autowired
    IUTransactionDao iuTransactionDao;

    @Transactional
    @Override
    public List<TransactionEntity> getAllTransaction(Integer idManageAdmin) {
        return (List<TransactionEntity>) this.iuTransactionDao.findManagerAdmin(idManageAdmin);
    }

    @Transactional
    @Override
    public List<TransactionEntity> getTransactionByUser(Integer id) {
        return (List<TransactionEntity>) this.iuTransactionDao.findTransactionByIdUser(id);
    }

    @Override
    public TransactionEntity save(TransactionEntity entity) {
        return this.iuTransactionDao.save(entity);
    }
}
