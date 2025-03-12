package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;

import java.util.List;

public interface ITransactionService {
    public List<TransactionEntity> getAllTransaction(Integer idManageAdmin);
    public List<TransactionEntity> getTransactionByUser(Integer id);
    public TransactionEntity save(TransactionEntity entity);

}
