package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.NotificationEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.INotificationService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:8080"})
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @Autowired
    private INotificationService notificationService;

    @PostMapping("/create")
    public RestResponse createNotification(@RequestBody Map<String, Object> request) {
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String title = request.get("title").toString();
            String message = request.get("message").toString();
            String type = request.get("type").toString();
            String additionalInfo = request.get("additionalInfo") != null ? 
                request.get("additionalInfo").toString() : null;
            
            NotificationEntity saved = notificationService.createNotificationWithUserData(
                userId, title, message, type, additionalInfo);
            return new RestResponse(HttpStatus.CREATED.value(), "Notificación creada", saved);
        } catch (Exception e) {
            return new RestResponse(HttpStatus.BAD_REQUEST.value(), "Error al crear notificación: " + e.getMessage(), null);
        }
    }

    @GetMapping("/user/{userId}")
    public RestResponse getUserNotifications(@PathVariable Long userId) {
        List<NotificationEntity> notifications = notificationService.findByUserId(userId);
        return new RestResponse(HttpStatus.OK.value(), "Notificaciones del usuario", notifications);
    }

    @GetMapping("/user/{userId}/unread")
    public RestResponse getUnreadNotifications(@PathVariable Long userId) {
        List<NotificationEntity> notifications = notificationService.findUnreadByUserId(userId);
        return new RestResponse(HttpStatus.OK.value(), "Notificaciones no leídas", notifications);
    }

    @PutMapping("/mark-read/{id}")
    public RestResponse markAsRead(@PathVariable Long id) {
        NotificationEntity notification = notificationService.markAsRead(id);
        if (notification != null) {
            return new RestResponse(HttpStatus.OK.value(), "Notificación marcada como leída", notification);
        }
        return new RestResponse(HttpStatus.NOT_FOUND.value(), "Notificación no encontrada", null);
    }
}