package com.bolsadeideas.springboot.backend.apirest.models.services;

import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Motor de mapeo automático de columnas del Excel a campos del Lead.
 * Utiliza sinónimos y similitud de texto (Levenshtein normalizado) para
 * determinar la correspondencia entre encabezados del archivo y campos del sistema.
 */
@Service
public class ColumnMappingEngine {

    private static final double SIMILARITY_THRESHOLD = 0.6;

    // Mapa de sinónimos para cada campo del Lead
    private static final Map<String, List<String>> FIELD_SYNONYMS = Map.of(
        "nombre", List.of("nombre", "name", "first_name", "firstname", "primer nombre", "nombres"),
        "apellido", List.of("apellido", "lastname", "last_name", "surname", "apellidos", "segundo nombre"),
        "lastCallStatus", List.of("last_call_status", "estado_llamada", "call_status", "status", "estado"),
        "pais", List.of("pais", "país", "country", "nacionalidad"),
        "telefono", List.of("telefono", "teléfono", "phone", "tel", "celular", "mobile", "número"),
        "email", List.of("email", "correo", "e-mail", "mail", "correo electrónico"),
        "campana", List.of("campaña", "campana", "campaign", "camp"),
        "fechaRegistro", List.of("fecha_registro", "fecha registro", "registration_date", "date", "fecha"),
        "comentarios", List.of("comentarios", "comments", "notas", "notes", "observaciones")
    );

    /**
     * Mapea los encabezados del Excel a campos del Lead.
     * Retorna un MappingResult con el mapeo columna→campo.
     * Las columnas no mapeadas se incluyen con value=null.
     *
     * Algoritmo:
     * 1. Normaliza headers (lowercase, trim, replace underscores/hyphens with spaces)
     * 2. Para cada header, verifica contra todos los sinónimos de cada campo
     * 3. Primero intenta coincidencia exacta contra sinónimos
     * 4. Si no hay coincidencia exacta, usa similitud de Levenshtein con umbral 0.6
     * 5. Asigna el mejor match (mayor similitud por encima del umbral)
     * 6. Asegura que ningún campo se mapee dos veces (primer match gana)
     */
    public MappingResult mapColumns(List<String> headers) {
        Map<Integer, String> columnMapping = new LinkedHashMap<>();
        Set<String> assignedFields = new HashSet<>();

        for (int i = 0; i < headers.size(); i++) {
            String header = headers.get(i);
            String normalizedHeader = normalize(header);

            String bestField = null;
            double bestSimilarity = 0.0;

            // Intentar mapear contra cada campo
            for (Map.Entry<String, List<String>> entry : FIELD_SYNONYMS.entrySet()) {
                String fieldName = entry.getKey();

                // Saltar campos ya asignados
                if (assignedFields.contains(fieldName)) {
                    continue;
                }

                List<String> synonyms = entry.getValue();

                // Primero intentar coincidencia exacta contra sinónimos normalizados
                for (String synonym : synonyms) {
                    String normalizedSynonym = normalize(synonym);
                    if (normalizedHeader.equals(normalizedSynonym)) {
                        bestField = fieldName;
                        bestSimilarity = 1.0;
                        break;
                    }
                }

                // Si ya encontramos coincidencia exacta, no buscar más
                if (bestSimilarity == 1.0) {
                    break;
                }

                // Si no hay coincidencia exacta, usar similitud de Levenshtein
                for (String synonym : synonyms) {
                    String normalizedSynonym = normalize(synonym);
                    double similarity = calculateSimilarity(normalizedHeader, normalizedSynonym);
                    if (similarity >= SIMILARITY_THRESHOLD && similarity > bestSimilarity) {
                        bestField = fieldName;
                        bestSimilarity = similarity;
                    }
                }
            }

            // Asignar el mejor match encontrado
            if (bestField != null) {
                columnMapping.put(i, bestField);
                assignedFields.add(bestField);
            } else {
                columnMapping.put(i, null);
            }
        }

        boolean hasUnmapped = columnMapping.containsValue(null);
        return new MappingResult(columnMapping, hasUnmapped);
    }

    /**
     * Calcula la similitud normalizada entre dos strings usando distancia de Levenshtein.
     * Retorna un valor entre 0.0 (sin similitud) y 1.0 (idénticos).
     */
    public double calculateSimilarity(String s1, String s2) {
        if (s1 == null || s2 == null) {
            return 0.0;
        }

        if (s1.equals(s2)) {
            return 1.0;
        }

        int maxLength = Math.max(s1.length(), s2.length());
        if (maxLength == 0) {
            return 1.0;
        }

        int distance = levenshteinDistance(s1, s2);
        return 1.0 - ((double) distance / maxLength);
    }

    /**
     * Normaliza un string para comparación:
     * - Convierte a minúsculas
     * - Elimina espacios al inicio y final
     * - Reemplaza guiones bajos y guiones con espacios
     */
    private String normalize(String input) {
        if (input == null) {
            return "";
        }
        return input.trim()
                .toLowerCase()
                .replace('_', ' ')
                .replace('-', ' ');
    }

    /**
     * Calcula la distancia de Levenshtein entre dos strings.
     * Usa programación dinámica con una matriz de (m+1) x (n+1).
     */
    private int levenshteinDistance(String s1, String s2) {
        int m = s1.length();
        int n = s2.length();

        int[][] dp = new int[m + 1][n + 1];

        for (int i = 0; i <= m; i++) {
            dp[i][0] = i;
        }
        for (int j = 0; j <= n; j++) {
            dp[0][j] = j;
        }

        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                int cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                dp[i][j] = Math.min(
                    Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                    dp[i - 1][j - 1] + cost
                );
            }
        }

        return dp[m][n];
    }
}
