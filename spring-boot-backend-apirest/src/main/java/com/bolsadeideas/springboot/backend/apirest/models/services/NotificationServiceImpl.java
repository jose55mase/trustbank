package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.INotificationDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.NotificationEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.INotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class NotificationServiceImpl implements INotificationService {

    @Autowired
    private INotificationDao notificationDao;
    
    @Autowired
    private IUserDao userDao;

    @Override
    @Transactional
    public NotificationEntity save(NotificationEntity notification) {
        return notificationDao.save(notification);
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationEntity> findByUserId(Long userId) {
        return notificationDao.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationEntity> findUnreadByUserId(Long userId) {
        return notificationDao.findByUserIdAndIsReadFalse(userId);
    }

    @Override
    @Transactional
    public NotificationEntity markAsRead(Long notificationId) {
        NotificationEntity notification = notificationDao.findById(notificationId).orElse(null);
        if (notification != null) {
            notification.setIsRead(true);
            return notificationDao.save(notification);
        }
        return null;
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationEntity findById(Long id) {
        return notificationDao.findById(id).orElse(null);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        notificationDao.deleteById(id);
    }

    @Override
    @Transactional
    public NotificationEntity createNotificationWithUserData(Long userId, String title, String message, String type, String additionalInfo) {
        NotificationEntity notification = new NotificationEntity();
        notification.setUserId(userId);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType(type);
        notification.setAdditionalInfo(additionalInfo);
        
        // Obtener datos del usuario para enriquecer la notificación
        UserEntity user = userDao.findById(userId).orElse(null);
        if (user != null) {
            notification.setUserName(user.getFullName());
            notification.setUserEmail(user.getEmail());
            notification.setUserPhone(user.getPhone());
        }
        
        return notificationDao.save(notification);
    }
}