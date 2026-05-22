package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.AdminRequestEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IAdminRequestService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ITransactionService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/api/admin-requests")
public class AdminRequestController {

    @Autowired
    private IAdminRequestService adminRequestService;
    
    @Autowired
    private IUserService userService;
    
    @Autowired
    private ITransactionService transactionService;

    @PostMapping("/create")
    public RestResponse createRequest(@RequestBody AdminRequestEntity request) {
        // Validar campos requeridos para transferencias bancarias
        if ("SEND_MONEY".equals(request.getRequestType())) {
            if (request.getBankName() == null || request.getAccountNumber() == null) {
                return new RestResponse(HttpStatus.BAD_REQUEST.value(), "Banco y número de cuenta son requeridos para transferencias", null);
            }
        }
        
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
            System.out.println("Iniciando actualización de saldo para usuario: " + request.getUserId() + ", tipo: " + request.getRequestType() + ", monto: " + request.getAmount());
            
            UserEntity user = userService.findById(request.getUserId());
            if (user != null) {
                Integer currentBalance = user.getMoneyclean() != null ? user.getMoneyclean() : 0;
                System.out.println("Usuario encontrado - ID: " + user.getId() + ", Saldo actual: " + currentBalance);
                
                String transactionType = "INCOME";
                String description = "";
                
                switch (request.getRequestType()) {
                    case "RECHARGE":
                    case "BALANCE_RECHARGE":
                        user.setMoneyclean(currentBalance + request.getAmount().intValue());
                        transactionType = "INCOME";
                        description = "Recarga de saldo aprobada";
                        break;
                        
                    case "CREDIT":
                        user.setMoneyclean(currentBalance + request.getAmount().intValue());
                        transactionType = "INCOME";
                        description = "Crédito aprobado";
                        break;
                        
                    case "SEND_MONEY":
                        user.setMoneyclean(currentBalance - request.getAmount().intValue());
                        transactionType = "EXPENSE";
                        description = "Envío de dinero aprobado";
                        break;
                        
                    default:
                        System.out.println("Tipo de solicitud no reconocido para actualización de saldo: " + request.getRequestType());
                        return;
                }
                
                userService.save(user);
                System.out.println("Saldo actualizado exitosamente para usuario " + user.getId() + ": " + user.getMoneyclean());
                
                // Crear registro de transacción para que aparezca en movimientos
                createTransaction(request, user, transactionType, description);
                
            } else {
                System.err.println("Usuario no encontrado con ID: " + request.getUserId());
            }
        } catch (Exception e) {
            System.err.println("Error actualizando saldo del usuario: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void createTransaction(AdminRequestEntity request, UserEntity user, String type, String description) {
        try {
            TransactionEntity transaction = new TransactionEntity();
            transaction.setUserId(user.getId());
            transaction.setAmount(request.getAmount().longValue());
            transaction.setType(type);
            transaction.setStatus("COMPLETED");
            transaction.setDescription(description + " - " + (request.getDetails() != null ? request.getDetails() : ""));
            transaction.setBanck("TrustBank");
            transaction.setNumber(System.currentTimeMillis());
            
            // Fecha actual en formato ISO
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
            transaction.setDate(sdf.format(new Date()));
            
            transactionService.save(transaction);
            System.out.println("Transacción creada para usuario " + user.getId() + ": " + type + " $" + request.getAmount());
        } catch (Exception e) {
            System.err.println("Error creando transacción: " + e.getMessage());
            e.printStackTrace();
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