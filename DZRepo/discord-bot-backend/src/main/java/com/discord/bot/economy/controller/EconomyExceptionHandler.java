package com.discord.bot.economy.controller;

import com.discord.bot.economy.exception.DayzNameAlreadyLinkedException;
import com.discord.bot.economy.exception.InsufficientBalanceException;
import com.discord.bot.economy.exception.InvalidAmountException;
import com.discord.bot.economy.exception.PlayerNotLinkedException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Global exception handler for the economy REST controllers.
 *
 * <p>Translates domain-specific exceptions into appropriate HTTP responses
 * with structured error bodies containing "error" and "message" fields.</p>
 */
@RestControllerAdvice(basePackages = "com.discord.bot.economy.controller")
public class EconomyExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(EconomyExceptionHandler.class);

    /**
     * Handles cases where a player profile is not linked to a Discord account.
     *
     * @param ex the exception
     * @return error response with 404 status
     */
    @ExceptionHandler(PlayerNotLinkedException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Map<String, Object> handlePlayerNotLinked(PlayerNotLinkedException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", "Player not linked");
        body.put("message", ex.getMessage());
        return body;
    }

    /**
     * Handles cases where a debit operation exceeds the player's current balance.
     *
     * @param ex the exception containing current balance and requested amount
     * @return error response with 400 status including balance details
     */
    @ExceptionHandler(InsufficientBalanceException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, Object> handleInsufficientBalance(InsufficientBalanceException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", "Insufficient balance");
        body.put("message", ex.getMessage());
        body.put("currentBalance", ex.getCurrentBalance());
        body.put("requestedAmount", ex.getRequestedAmount());
        return body;
    }

    /**
     * Handles cases where a credit or debit amount is invalid (non-positive).
     *
     * @param ex the exception
     * @return error response with 400 status
     */
    @ExceptionHandler(InvalidAmountException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, Object> handleInvalidAmount(InvalidAmountException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", "Invalid amount");
        body.put("message", ex.getMessage());
        return body;
    }

    /**
     * Handles cases where a DayZ name is already linked to another Discord account.
     *
     * @param ex the exception containing the conflicting DayZ name
     * @return error response with 409 status including the conflicting name
     */
    @ExceptionHandler(DayzNameAlreadyLinkedException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public Map<String, Object> handleDayzNameAlreadyLinked(DayzNameAlreadyLinkedException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", "DayZ name already linked");
        body.put("message", ex.getMessage());
        body.put("dayzName", ex.getDayzName());
        return body;
    }

    /**
     * Catches any unhandled exception to prevent leaking internal details.
     * Logs the full stack trace for debugging while returning a generic message.
     *
     * @param ex the unexpected exception
     * @return generic error response with 500 status
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Map<String, Object> handleGenericException(Exception ex) {
        log.error("Unexpected error in economy controller", ex);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", "Internal server error");
        body.put("message", "An unexpected error occurred. Please try again later.");
        return body;
    }
}
