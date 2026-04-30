package com.discord.bot.nitrado.exception;

/**
 * Exception for network/timeout errors when communicating with the Nitrado API.
 * Extends RuntimeException directly since this is not an HTTP response error.
 */
public class NitradoConnectionException extends RuntimeException {

    public NitradoConnectionException(String message, Throwable cause) {
        super(message, cause);
    }
}
