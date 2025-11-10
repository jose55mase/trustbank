package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.NotificationEntity;
import com.bolsadeideas.springboot.backend.apirest.models.dao.INotificationDao;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:8080"})
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @Autowired
    private INotificationDao notificationDao;

    @PostMapping("/create")
    public RestResponse createNotification(@RequestBody NotificationEntity notification) {
        NotificationEntity saved = notificationDao.save(notification);
        return new RestResponse(HttpStatus.CREATED.value(), "Notificación creada", saved);
    }

    @GetMapping("/user/{userId}")
    public RestResponse getUserNotifications(@PathVariable Long userId) {
        List<NotificationEntity> notifications = notificationDao.findByUserIdOrderByCreatedAtDesc(userId);
        return new RestResponse(HttpStatus.OK.value(), "Notificaciones del usuario", notifications);
    }

    @GetMapping("/user/{userId}/unread")
    public RestResponse getUnreadNotifications(@PathVariable Long userId) {
        List<NotificationEntity> notifications = notificationDao.findByUserIdAndIsReadFalse(userId);
        return new RestResponse(HttpStatus.OK.value(), "Notificaciones no leídas", notifications);
    }

    @PutMapping("/mark-read/{id}")
    public RestResponse markAsRead(@PathVariable Long id) {
        NotificationEntity notification = notificationDao.findById(id).orElse(null);
        if (notification != null) {
            notification.setIsRead(true);
            notificationDao.save(notification);
            return new RestResponse(HttpStatus.OK.value(), "Notificación marcada como leída", notification);
        }
        return new RestResponse(HttpStatus.NOT_FOUND.value(), "Notificación no encontrada", null);
    }
}