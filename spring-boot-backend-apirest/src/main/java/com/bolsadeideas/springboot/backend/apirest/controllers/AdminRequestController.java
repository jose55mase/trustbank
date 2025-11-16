package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IAdminRequestService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:8080"})
@RestController
@RequestMapping("/api/admin-requests")
public class AdminRequestController {

    @Autowired
    private IAdminRequestService adminRequestService;
    
    @Autowired
    private IUserService userService;

    @PostMapping("/create")
    public RestResponse createRequest(@RequestBody AdminRequestEntity request) {
        AdminRequestEntity savedRequest = adminRequestService.save(request);
        return new RestResponse(HttpStatus.CREATED.value(), "Solicitud creada", savedRequest);
    }

    @GetMapping("/all")
    public RestResponse getAllRequests() {
        List<AdminRequestEntity> requests = adminRequestService.findAll();
        return new RestResponse(HttpStatus.OK.value(), "Todas las solicitudes", requests);
    }

    @GetMapping("/pending")
    public RestResponse getPendingRequests() {
        List<AdminRequestEntity> requests = adminRequestService.findPendingRequests();
        return new RestResponse(HttpStatus.OK.value(), "Solicitudes pendientes", requests);
    }

    @GetMapping("/user/{userId}")
    public RestResponse getRequestsByUser(@PathVariable Long userId) {
        List<AdminRequestEntity> requests = adminRequestService.findByUserId(userId);
        return new RestResponse(HttpStatus.OK.value(), "Solicitudes del usuario", requests);
    }

    @GetMapping("/type/{requestType}")
    public RestResponse getRequestsByType(@PathVariable String requestType) {
        List<AdminRequestEntity> requests = adminRequestService.findByRequestType(requestType);
        return new RestResponse(HttpStatus.OK.value(), "Solicitudes por tipo", requests);
    }

    @PutMapping("/process/{id}")
    public RestResponse processRequest(
            @PathVariable Long id,
            @RequestParam String status,
            @RequestParam(required = false) String adminNotes) {
        
        AdminRequestEntity request = adminRequestService.findById(id);
        if (request == null) {
            return new RestResponse(HttpStatus.NOT_FOUND.value(), "Solicitud no encontrada", null);
        }

        // Actualizar estado de la solicitud
        request.setStatus(status);
        request.setProcessedAt(new Date());
        if (adminNotes != null) {
            request.setAdminNotes(adminNotes);
        }

        // Si la solicitud es aprobada, actualizar saldo del usuario
        if ("APPROVED".equals(status)) {
            updateUserBalance(request);
        }

        AdminRequestEntity updatedRequest = adminRequestService.save(request);
        return new RestResponse(HttpStatus.OK.value(), "Solicitud procesada", updatedRequest);
    }
    
    private void updateUserBalance(AdminRequestEntity request) {
        try {
            UserEntity user = userService.findById(request.getUserId());
            if (user != null) {
                Integer currentBalance = user.getMoneyclean() != null ? user.getMoneyclean() : 0;
                
                switch (request.getRequestType()) {
                    case "RECHARGE":
                    case "BALANCE_RECHARGE":
                        // Agregar dinero al saldo
                        user.setMoneyclean(currentBalance + request.getAmount().intValue());
                        break;
                        
                    case "SEND_MONEY":
                        // Restar dinero del saldo
                        user.setMoneyclean(currentBalance - request.getAmount().intValue());
                        break;
                        
                    default:
                        // Para otros tipos de solicitud, no modificar saldo
                        return;
                }
                
                userService.save(user);
            }
        } catch (Exception e) {
            // Log error pero no fallar la transacción principal
            System.err.println("Error actualizando saldo del usuario: " + e.getMessage());
        }
    }

    @GetMapping("/status/{status}")
    public RestResponse getRequestsByStatus(@PathVariable String status) {
        List<AdminRequestEntity> requests = adminRequestService.findByStatus(status);
        return new RestResponse(HttpStatus.OK.value(), "Solicitudes por estado", requests);
    }

    @DeleteMapping("/{id}")
    public RestResponse deleteRequest(@PathVariable Long id) {
        adminRequestService.delete(id);
        return new RestResponse(HttpStatus.OK.value(), "Solicitud eliminada", null);
    }
}