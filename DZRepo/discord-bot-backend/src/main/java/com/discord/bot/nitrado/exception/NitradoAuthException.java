package com.discord.bot.nitrado.exception;

/**
 * Exception for authentication/authorization errors from the Nitrado API (HTTP 401/403).
 */
public class NitradoAuthException extends NitradoApiException {

    public NitradoAuthException(String message) {
        super(message, 401);
    }
}
