package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.exception.InsufficientBalanceException;
import com.discord.bot.economy.exception.InvalidAmountException;
import com.discord.bot.economy.exception.SelfTransferException;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransferResult;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.economy.service.PlayerLinkService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Optional;

/**
 * Slash command {@code /transferir} that allows a linked player to transfer
 * Coins to another linked player.
 *
 * <p>Validates that both sender and receiver have linked accounts, the receiver
 * is not a bot, the sender is not transferring to themselves, and the amount
 * is valid. On success, replies with a green embed showing transfer details.</p>
 */
@Component
public class TransferirCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(TransferirCommand.class);

    private final EconomyService economyService;
    private final PlayerLinkService playerLinkService;

    public TransferirCommand(EconomyService economyService, PlayerLinkService playerLinkService) {
        this.economyService = economyService;
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "transferir";
    }

    @Override
    public String getDescription() {
        return "Transfiere Coins a otro jugador";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addOption(OptionType.USER, "usuario", "Jugador al que transferir monedas", true)
                .addOption(OptionType.INTEGER, "cantidad", "Cantidad de Coins a transferir", true);
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        try {
            User targetUser = event.getOption("usuario").getAsUser();
            long cantidad = event.getOption("cantidad").getAsLong();

            // Validate target is not a bot
            if (targetUser.isBot()) {
                event.reply("❌ No puedes transferir monedas a un bot.")
                        .setEphemeral(true).queue();
                return;
            }

            // Validate sender ≠ receiver
            if (event.getUser().getId().equals(targetUser.getId())) {
                event.reply("❌ No puedes transferirte monedas a ti mismo.")
                        .setEphemeral(true).queue();
                return;
            }

            // Look up sender profile
            Optional<PlayerProfile> senderOpt = playerLinkService.findByDiscordId(event.getUser().getId());
            if (senderOpt.isEmpty()) {
                event.reply("❌ Debes vincular tu cuenta primero con `/vincular`.")
                        .setEphemeral(true).queue();
                return;
            }

            // Look up receiver profile
            Optional<PlayerProfile> receiverOpt = playerLinkService.findByDiscordId(targetUser.getId());
            if (receiverOpt.isEmpty()) {
                event.reply("❌ El usuario no tiene una cuenta vinculada.")
                        .setEphemeral(true).queue();
                return;
            }

            PlayerProfile senderProfile = senderOpt.get();
            PlayerProfile receiverProfile = receiverOpt.get();

            TransferResult result = economyService.transferCoins(senderProfile, receiverProfile, cantidad);

            var embed = new EmbedBuilder()
                    .setColor(new Color(0x2ECC71))
                    .setTitle("✅ Transferencia Exitosa")
                    .addField("Emisor", event.getUser().getAsMention(), true)
                    .addField("Receptor", targetUser.getAsMention(), true)
                    .addField("Cantidad", formatBalance(cantidad) + " Coins", false)
                    .addField("Nuevo balance emisor",
                            formatBalance(result.senderTransaction().getBalanceAfter()) + " Coins", true)
                    .addField("Nuevo balance receptor",
                            formatBalance(result.receiverTransaction().getBalanceAfter()) + " Coins", true)
                    .build();

            event.replyEmbeds(embed).queue();

        } catch (InvalidAmountException e) {
            event.reply("❌ La cantidad debe ser un número positivo.")
                    .setEphemeral(true).queue();
        } catch (InsufficientBalanceException e) {
            event.reply("❌ Balance insuficiente. Tu balance actual es: "
                    + formatBalance(e.getCurrentBalance()) + " Coins.")
                    .setEphemeral(true).queue();
        } catch (SelfTransferException e) {
            event.reply("❌ No puedes transferirte monedas a ti mismo.")
                    .setEphemeral(true).queue();
        } catch (Exception e) {
            log.error("Error al ejecutar /transferir: {}", e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }

    private String formatBalance(long amount) {
        NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);
        return numberFormat.format(amount);
    }
}
