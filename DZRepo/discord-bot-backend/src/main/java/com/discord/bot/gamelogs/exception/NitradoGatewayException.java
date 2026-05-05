package com.discord.bot.gamelogs.exception;

/**
 * Exception thrown when the Nitrado API is unreachable or returns an error
 * while fetching game logs. This should result in an HTTP 502 Bad Gateway response.
 */
public class NitradoGatewayException extends RuntimeException {

    public NitradoGatewayException(String message, Throwable cause) {
        super(message, cause);
    }

    public NitradoGatewayException(String message) {
        super(message);
    }
}
