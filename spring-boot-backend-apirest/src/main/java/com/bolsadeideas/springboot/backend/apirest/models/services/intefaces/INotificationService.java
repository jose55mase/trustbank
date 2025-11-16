package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.NotificationEntity;
import java.util.List;

public interface INotificationService {
    
    NotificationEntity save(NotificationEntity notification);
    
    List<NotificationEntity> findByUserId(Long userId);
    
    List<NotificationEntity> findUnreadByUserId(Long userId);
    
    NotificationEntity markAsRead(Long notificationId);
    
    NotificationEntity findById(Long id);
    
    void delete(Long id);
    
    NotificationEntity createNotificationWithUserData(Long userId, String title, String message, String type, String additionalInfo);
}