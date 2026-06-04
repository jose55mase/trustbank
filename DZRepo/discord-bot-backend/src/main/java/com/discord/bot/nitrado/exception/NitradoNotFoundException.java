package com.discord.bot.nitrado.exception;

/**
 * Exception for resource not found errors from the Nitrado API (HTTP 404)
 * or logical resource not found scenarios.
 */
public class NitradoNotFoundException extends NitradoApiException {

    public NitradoNotFoundException(String message) {
        super(message, 404);
    }
}
