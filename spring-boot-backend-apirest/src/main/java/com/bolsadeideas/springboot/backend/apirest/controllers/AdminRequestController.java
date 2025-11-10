package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IAdminRequestService;
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

        request.setStatus(status);
        request.setProcessedAt(new Date());
        if (adminNotes != null) {
            request.setAdminNotes(adminNotes);
        }

        AdminRequestEntity updatedRequest = adminRequestService.save(request);
        return new RestResponse(HttpStatus.OK.value(), "Solicitud procesada", updatedRequest);
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