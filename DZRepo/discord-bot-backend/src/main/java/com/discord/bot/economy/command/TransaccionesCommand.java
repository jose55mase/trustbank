package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.model.CurrencyTransaction;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.economy.service.PlayerLinkService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Slash command {@code /transacciones} that displays the player's last 10
 * TNT Coins transactions.
 *
 * <p>Shows an embed listing each transaction with its type (translated to Spanish),
 * amount (with +/- prefix), date/time, and description.</p>
 */
@Component
public class TransaccionesCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(TransaccionesCommand.class);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final EconomyService economyService;
    private final PlayerLinkService playerLinkService;

    public TransaccionesCommand(EconomyService economyService, PlayerLinkService playerLinkService) {
        this.economyService = economyService;
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "transacciones";
    }

    @Override
    public String getDescription() {
        return "Muestra tus últimas transacciones de TNT Coins";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String discordId = event.getUser().getId();

        try {
            Optional<PlayerProfile> optProfile = playerLinkService.findByDiscordId(discordId);

            if (optProfile.isEmpty()) {
                event.reply("❌ No tienes una cuenta vinculada. Debes vincular tu cuenta primero usando `/vincular`.")
                        .setEphemeral(true).queue();
                return;
            }

            PlayerProfile profile = optProfile.get();
            List<CurrencyTransaction> transactions = economyService.getRecentTransactions(profile);

            if (transactions.isEmpty()) {
                event.reply("📭 No tienes transacciones registradas.")
                        .setEphemeral(true).queue();
                return;
            }

            NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);

            StringBuilder description = new StringBuilder();
            for (CurrencyTransaction tx : transactions) {
                String typeLabel = translateTransactionType(tx.getType());
                String amountPrefix = isDebitType(tx.getType()) ? "-" : "+";
                String formattedAmount = amountPrefix + numberFormat.format(tx.getAmount());
                String date = tx.getCreatedAt().format(DATE_FORMATTER);
                String txDescription = tx.getDescription() != null ? tx.getDescription() : "";

                description.append(typeLabel)
                        .append(" | **").append(formattedAmount).append("** TNT Coins")
                        .append(" | ").append(date)
                        .append("\n").append(txDescription)
                        .append("\n\n");
            }

            var embed = new EmbedBuilder()
                    .setColor(new Color(0x3498DB))
                    .setTitle("📜 Últimas transacciones de " + profile.getDayzPlayerName())
                    .setDescription(description.toString().trim())
                    .build();

            event.replyEmbeds(embed).queue();
        } catch (Exception e) {
            log.error("Error al consultar transacciones para Discord ID {}: {}", discordId, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }

    /**
     * Translates a {@link TransactionType} to a human-readable Spanish label with emoji.
     */
    static String translateTransactionType(TransactionType type) {
        return switch (type) {
            case ZOMBIE_KILL_REWARD -> "🧟 Recompensa Zombie";
            case ADMIN_CREDIT -> "💰 Crédito Admin";
            case ADMIN_DEBIT -> "💸 Débito Admin";
            case PLAYER_TRANSFER_SENT -> "📤 Transferencia Enviada";
            case PLAYER_TRANSFER_RECEIVED -> "📥 Transferencia Recibida";
        };
    }

    /**
     * Returns {@code true} if the transaction type represents a debit (money leaving the account).
     */
    private static boolean isDebitType(TransactionType type) {
        return type == TransactionType.ADMIN_DEBIT || type == TransactionType.PLAYER_TRANSFER_SENT;
    }
}
