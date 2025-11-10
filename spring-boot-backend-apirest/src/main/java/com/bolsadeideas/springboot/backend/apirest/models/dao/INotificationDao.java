package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.NotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface INotificationDao extends JpaRepository<NotificationEntity, Long> {
    List<NotificationEntity> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<NotificationEntity> findByUserIdAndIsReadFalse(Long userId);
}