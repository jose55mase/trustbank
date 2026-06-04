package com.discord.bot.economy.service;

import com.discord.bot.economy.dto.EconomyConfigUpdateDto;
import com.discord.bot.economy.exception.InsufficientBalanceException;
import com.discord.bot.economy.exception.InvalidAmountException;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.exception.SelfTransferException;
import com.discord.bot.economy.model.CurrencyTransaction;
import com.discord.bot.economy.model.EconomyConfig;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.model.TransferResult;
import com.discord.bot.economy.repository.CurrencyTransactionRepository;
import com.discord.bot.economy.repository.EconomyConfigRepository;
import com.discord.bot.economy.repository.PlayerProfileRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service responsible for economy operations: crediting/debiting coins,
 * querying balances and transactions, and managing economy configuration.
 *
 * <p>Credit and debit operations are transactional — the player's balance
 * and the corresponding {@link CurrencyTransaction} record are persisted
 * atomically.</p>
 */
@Service
public class EconomyService {

    private static final Logger log = LoggerFactory.getLogger(EconomyService.class);

    private final PlayerProfileRepository playerProfileRepository;
    private final CurrencyTransactionRepository currencyTransactionRepository;
    private final EconomyConfigRepository economyConfigRepository;

    public EconomyService(PlayerProfileRepository playerProfileRepository,
                          CurrencyTransactionRepository currencyTransactionRepository,
                          EconomyConfigRepository economyConfigRepository) {
        this.playerProfileRepository = playerProfileRepository;
        this.currencyTransactionRepository = currencyTransactionRepository;
        this.economyConfigRepository = economyConfigRepository;
    }

    /**
     * Credits coins to a player's balance and records the transaction atomically.
     *
     * @param profile     the player profile to credit
     * @param amount      the number of coins to credit (must be &gt; 0)
     * @param type        the transaction type
     * @param description a human-readable description of the transaction
     * @return the created {@link CurrencyTransaction}
     * @throws InvalidAmountException if amount is &lt;= 0
     */
    @Transactional
    public CurrencyTransaction creditCoins(PlayerProfile profile, long amount,
                                           TransactionType type, String description) {
        if (amount <= 0) {
            throw new InvalidAmountException("La cantidad debe ser positiva. Recibido: " + amount);
        }

        profile.setBalance(profile.getBalance() + amount);
        playerProfileRepository.save(profile);

        CurrencyTransaction transaction = new CurrencyTransaction(
                profile, type, amount, profile.getBalance(), description, LocalDateTime.now());
        CurrencyTransaction saved = currencyTransactionRepository.save(transaction);

        log.info("Credited {} coins to player '{}' (type={}). New balance: {}",
                amount, profile.getDayzPlayerName(), type, profile.getBalance());
        return saved;
    }

    /**
     * Debits coins from a player's balance and records the transaction atomically.
     *
     * @param profile     the player profile to debit
     * @param amount      the number of coins to debit (must be &gt; 0)
     * @param type        the transaction type
     * @param description a human-readable description of the transaction
     * @return the created {@link CurrencyTransaction}
     * @throws InvalidAmountException       if amount is &lt;= 0
     * @throws InsufficientBalanceException if amount exceeds the player's current balance
     */
    @Transactional
    public CurrencyTransaction debitCoins(PlayerProfile profile, long amount,
                                          TransactionType type, String description) {
        if (amount <= 0) {
            throw new InvalidAmountException("La cantidad debe ser positiva. Recibido: " + amount);
        }

        if (amount > profile.getBalance()) {
            throw new InsufficientBalanceException(
                    "Balance insuficiente. Balance actual: " + profile.getBalance()
                            + ", cantidad solicitada: " + amount,
                    profile.getBalance(), amount);
        }

        profile.setBalance(profile.getBalance() - amount);
        playerProfileRepository.save(profile);

        CurrencyTransaction transaction = new CurrencyTransaction(
                profile, type, amount, profile.getBalance(), description, LocalDateTime.now());
        CurrencyTransaction saved = currencyTransactionRepository.save(transaction);

        log.info("Debited {} coins from player '{}' (type={}). New balance: {}",
                amount, profile.getDayzPlayerName(), type, profile.getBalance());
        return saved;
    }

    /**
     * Transfers coins from one player to another atomically.
     * Debits the sender, credits the receiver, and creates transaction
     * records for both parties within a single database transaction.
     *
     * @param sender   the player profile sending coins
     * @param receiver the player profile receiving coins
     * @param amount   the number of coins to transfer (must be &gt; 0)
     * @return a {@link TransferResult} containing both transaction records
     * @throws InvalidAmountException       if amount is &lt;= 0
     * @throws SelfTransferException        if sender and receiver are the same player
     * @throws InsufficientBalanceException if sender's balance is less than amount
     */
    @Transactional
    public TransferResult transferCoins(PlayerProfile sender, PlayerProfile receiver, long amount) {
        if (amount <= 0) {
            throw new InvalidAmountException("La cantidad debe ser positiva. Recibido: " + amount);
        }

        if (sender.getId().equals(receiver.getId())) {
            throw new SelfTransferException("No puedes transferirte monedas a ti mismo.");
        }

        if (sender.getBalance() < amount) {
            throw new InsufficientBalanceException(
                    "Balance insuficiente. Balance actual: " + sender.getBalance()
                            + ", cantidad solicitada: " + amount,
                    sender.getBalance(), amount);
        }

        // Debit sender
        sender.setBalance(sender.getBalance() - amount);
        playerProfileRepository.save(sender);

        CurrencyTransaction sentTransaction = new CurrencyTransaction(
                sender, TransactionType.PLAYER_TRANSFER_SENT, amount, sender.getBalance(),
                "Transferencia enviada a " + receiver.getDayzPlayerName(), LocalDateTime.now());
        CurrencyTransaction savedSentTx = currencyTransactionRepository.save(sentTransaction);

        // Credit receiver
        receiver.setBalance(receiver.getBalance() + amount);
        playerProfileRepository.save(receiver);

        CurrencyTransaction receivedTransaction = new CurrencyTransaction(
                receiver, TransactionType.PLAYER_TRANSFER_RECEIVED, amount, receiver.getBalance(),
                "Transferencia recibida de " + sender.getDayzPlayerName(), LocalDateTime.now());
        CurrencyTransaction savedReceivedTx = currencyTransactionRepository.save(receivedTransaction);

        log.info("Transferred {} coins from '{}' to '{}'. Sender balance: {}, Receiver balance: {}",
                amount, sender.getDayzPlayerName(), receiver.getDayzPlayerName(),
                sender.getBalance(), receiver.getBalance());

        return new TransferResult(savedSentTx, savedReceivedTx);
    }

    /**
     * Returns the current coin balance for the player identified by Discord ID.
     *
     * @param discordId the Discord user ID
     * @return the player's current balance
     * @throws PlayerNotLinkedException if no profile exists for the given Discord ID
     */
    public long getBalance(String discordId) {
        PlayerProfile profile = playerProfileRepository.findByDiscordId(discordId)
                .orElseThrow(() -> new PlayerNotLinkedException(
                        "No se encontró una cuenta vinculada para el Discord ID: " + discordId));
        return profile.getBalance();
    }

    /**
     * Returns the 10 most recent transactions for the given player profile,
     * ordered from newest to oldest.
     *
     * @param profile the player profile
     * @return list of up to 10 recent transactions
     */
    public List<CurrencyTransaction> getRecentTransactions(PlayerProfile profile) {
        return currencyTransactionRepository.findTop10ByPlayerProfileOrderByCreatedAtDesc(profile);
    }

    /**
     * Returns a paginated view of all transactions, ordered from newest to oldest.
     *
     * @param pageable pagination parameters
     * @return a page of transactions
     */
    public Page<CurrencyTransaction> getAllTransactions(Pageable pageable) {
        return currencyTransactionRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    // ---- Economy Configuration ----

    /**
     * Retrieves the economy configuration for the given guild.
     * If no configuration exists, a default one is created and persisted.
     *
     * @param guildId the Discord guild (server) ID
     * @return the economy configuration for the guild
     */
    @Transactional
    public EconomyConfig getConfig(String guildId) {
        return economyConfigRepository.findByGuildId(guildId)
                .orElseGet(() -> {
                    log.info("No economy config found for guild '{}'. Creating default config.", guildId);
                    EconomyConfig defaultConfig = new EconomyConfig(guildId);
                    return economyConfigRepository.save(defaultConfig);
                });
    }

    /**
     * Updates the economy configuration for the given guild.
     * Only non-null fields in the DTO are applied.
     *
     * @param guildId the Discord guild (server) ID
     * @param dto     the update DTO with optional fields
     * @return the updated economy configuration
     * @throws InvalidAmountException if {@code coinsPerZombieKill} is provided and is not positive
     */
    @Transactional
    public EconomyConfig updateConfig(String guildId, EconomyConfigUpdateDto dto) {
        EconomyConfig config = getConfig(guildId);

        if (dto.coinsPerZombieKill() != null) {
            if (dto.coinsPerZombieKill() <= 0) {
                throw new InvalidAmountException(
                        "coinsPerZombieKill debe ser un número positivo. Recibido: "
                                + dto.coinsPerZombieKill());
            }
            config.setCoinsPerZombieKill(dto.coinsPerZombieKill());
        }

        if (dto.meleeWeapons() != null) {
            String csv = dto.meleeWeapons().stream()
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.joining(","));
            config.setMeleeWeapons(csv);
        }

        if (dto.enabled() != null) {
            config.setEnabled(dto.enabled());
        }

        EconomyConfig saved = economyConfigRepository.save(config);
        log.info("Updated economy config for guild '{}': coinsPerZombieKill={}, enabled={}",
                guildId, saved.getCoinsPerZombieKill(), saved.isEnabled());
        return saved;
    }

    /**
     * Checks whether the given weapon is classified as a melee weapon
     * according to the guild's economy configuration.
     *
     * <p>The comparison is case-insensitive.</p>
     *
     * @param weapon  the weapon name to check
     * @param guildId the Discord guild (server) ID
     * @return {@code true} if the weapon is in the configured melee weapons list
     */
    public boolean isMeleeWeapon(String weapon, String guildId) {
        EconomyConfig config = getConfig(guildId);
        String meleeWeapons = config.getMeleeWeapons();

        if (meleeWeapons == null || meleeWeapons.isBlank()) {
            return false;
        }

        return Arrays.stream(meleeWeapons.split(","))
                .map(String::trim)
                .anyMatch(w -> w.equalsIgnoreCase(weapon));
    }
}
