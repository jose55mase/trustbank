package com.discord.bot.nitrado.exception;

/**
 * Base exception for errors received from the Nitrado API.
 * Contains the HTTP status code from the Nitrado response.
 */
public class NitradoApiException extends RuntimeException {

    private final int statusCode;

    public NitradoApiException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
