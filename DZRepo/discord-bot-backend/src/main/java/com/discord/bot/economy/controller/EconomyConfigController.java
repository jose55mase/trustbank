package com.discord.bot.economy.controller;

import com.discord.bot.economy.dto.EconomyConfigDto;
import com.discord.bot.economy.dto.EconomyConfigUpdateDto;
import com.discord.bot.economy.dto.TransactionDto;
import com.discord.bot.economy.model.EconomyConfig;
import com.discord.bot.economy.service.EconomyService;

import jakarta.validation.Valid;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for economy configuration and transaction history.
 *
 * <p>Exposes endpoints consumed by the Flutter admin app to read/update
 * economy settings and browse paginated transaction history.</p>
 */
@RestController
@RequestMapping("/api/economy")
public class EconomyConfigController {

    private final EconomyService economyService;

    public EconomyConfigController(EconomyService economyService) {
        this.economyService = economyService;
    }

    /**
     * Returns the economy configuration for the given guild.
     * If no configuration exists yet, a default one is created automatically.
     *
     * @param guildId the Discord guild (server) ID
     * @return the current economy configuration
     */
    @GetMapping("/config")
    public EconomyConfigDto getConfig(@RequestParam String guildId) {
        EconomyConfig config = economyService.getConfig(guildId);
        return EconomyConfigDto.fromConfig(config);
    }

    /**
     * Updates the economy configuration for the given guild.
     * Only non-null fields in the request body are applied.
     *
     * @param guildId the Discord guild (server) ID
     * @param dto     the update payload with optional fields
     * @return the updated economy configuration
     */
    @PutMapping("/config")
    public EconomyConfigDto updateConfig(@RequestParam String guildId,
                                         @RequestBody @Valid EconomyConfigUpdateDto dto) {
        EconomyConfig config = economyService.updateConfig(guildId, dto);
        return EconomyConfigDto.fromConfig(config);
    }

    /**
     * Returns a paginated list of all transactions, ordered from newest to oldest.
     *
     * @param page the zero-based page index (default 0)
     * @param size the page size (default 20)
     * @return a page of transaction DTOs
     */
    @GetMapping("/transactions")
    public Page<TransactionDto> getTransactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return economyService.getAllTransactions(pageable)
                .map(TransactionDto::fromTransaction);
    }
}
