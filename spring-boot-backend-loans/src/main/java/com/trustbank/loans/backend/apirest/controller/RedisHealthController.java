package com.trustbank.loans.backend.apirest.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/redis")
@CrossOrigin(origins = "*")
public class RedisHealthController {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private RedisConnectionFactory connectionFactory;

    /**
     * Verifica la conexión a Redis y retorna información del servidor.
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        try {
            String pong = connectionFactory.getConnection().ping();
            response.put("status", "UP");
            response.put("ping", pong);

            // Info básica de Redis
            java.util.Properties info = connectionFactory.getConnection().info();
            if (info != null) {
                response.put("redis_version", info.getProperty("redis_version"));
                response.put("connected_clients", info.getProperty("connected_clients"));
                response.put("used_memory_human", info.getProperty("used_memory_human"));
                response.put("uptime_in_seconds", info.getProperty("uptime_in_seconds"));
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "DOWN");
            response.put("error", e.getMessage());
            return ResponseEntity.status(503).body(response);
        }
    }

    /**
     * Lista todas las claves de caché almacenadas en Redis.
     */
    @GetMapping("/keys")
    public ResponseEntity<Map<String, Object>> getKeys() {
        Map<String, Object> response = new HashMap<>();
        try {
            Set<String> keys = redisTemplate.keys("*");
            response.put("totalKeys", keys != null ? keys.size() : 0);
            response.put("keys", keys);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("error", e.getMessage());
            return ResponseEntity.status(503).body(response);
        }
    }

    /**
     * Limpia todo el caché de Redis.
     */
    @DeleteMapping("/flush")
    public ResponseEntity<Map<String, String>> flushCache() {
        Map<String, String> response = new HashMap<>();
        try {
            connectionFactory.getConnection().flushDb();
            response.put("status", "OK");
            response.put("message", "Caché de Redis limpiado exitosamente");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("error", e.getMessage());
            return ResponseEntity.status(503).body(response);
        }
    }
}
