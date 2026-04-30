package com.discord.bot.nitrado.exception;

import com.discord.bot.nitrado.dto.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(basePackages = "com.discord.bot.nitrado")
public class NitradoExceptionHandler {

    @ExceptionHandler(NitradoAuthException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public ErrorResponse handleAuth(NitradoAuthException ex) {
        return new ErrorResponse("UNAUTHORIZED", ex.getMessage());
    }

    @ExceptionHandler(NitradoServerException.class)
    @ResponseStatus(HttpStatus.BAD_GATEWAY)
    public ErrorResponse handleServerError(NitradoServerException ex) {
        return new ErrorResponse("BAD_GATEWAY", ex.getMessage());
    }

    @ExceptionHandler(NitradoNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(NitradoNotFoundException ex) {
        return new ErrorResponse("NOT_FOUND", ex.getMessage());
    }

    @ExceptionHandler(NitradoApiException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleApiError(NitradoApiException ex) {
        return new ErrorResponse("BAD_REQUEST", ex.getMessage());
    }

    @ExceptionHandler(NitradoConnectionException.class)
    @ResponseStatus(HttpStatus.GATEWAY_TIMEOUT)
    public ErrorResponse handleConnectionError(NitradoConnectionException ex) {
        return new ErrorResponse("GATEWAY_TIMEOUT", ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleBadRequest(IllegalArgumentException ex) {
        return new ErrorResponse("BAD_REQUEST", ex.getMessage());
    }
}
