package com.discord.bot.nitrado.dto;

/**
 * Enumeración de acciones de control del servidor DayZ.
 * Soporta conversión case-insensitive desde String.
 */
public enum ServerAction {
    START, STOP, RESTART;

    /**
     * Convierte un String a ServerAction de forma case-insensitive.
     *
     * @param value el nombre de la acción (e.g., "start", "STOP", "Restart")
     * @return la ServerAction correspondiente
     * @throws IllegalArgumentException si el valor no corresponde a una acción válida
     */
    public static ServerAction fromString(String value) {
        try {
            return ServerAction.valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                "Acción no válida: '" + value + "'. Acciones permitidas: start, stop, restart");
        }
    }
}
