package com.bolsadeideas.springboot.backend.apirest.models.dao;


import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IUTransactionDao extends CrudRepository<TransactionEntity, Long> {
    @Query(value = "SELECT *  from transactionsbanck  where user_id=?1 ORDER BY id DESC"
            , nativeQuery = true)
    public List<TransactionEntity> findTransactionByIdUser(Integer integer);
    @Query(value = "SELECT *  from transactionsbanck ORDER BY id DESC", nativeQuery = true)
    public  List<TransactionEntity> findAll();
}
