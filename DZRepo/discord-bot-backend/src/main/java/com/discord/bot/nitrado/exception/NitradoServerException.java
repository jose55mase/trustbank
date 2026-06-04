package com.discord.bot.nitrado.exception;

/**
 * Exception for server errors from the Nitrado API (HTTP 5xx).
 */
public class NitradoServerException extends NitradoApiException {

    public NitradoServerException(String message, int statusCode) {
        super(message, statusCode);
    }
}
