package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.exception.InsufficientBalanceException;
import com.discord.bot.economy.exception.InvalidAmountException;
import com.discord.bot.economy.model.CurrencyTransaction;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.economy.service.PlayerLinkService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.User;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Optional;

/**
 * Slash command {@code /economia} with subcommands {@code dar} and {@code quitar}.
 *
 * <p>Allows Discord administrators to credit or debit Coins from players.
 * Requires administrator permissions. Validates that the target user has a
 * linked account, the amount is positive, and (for debits) the balance is
 * sufficient.</p>
 */
@Component
public class EconomiaCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(EconomiaCommand.class);

    private final EconomyService economyService;
    private final PlayerLinkService playerLinkService;

    public EconomiaCommand(EconomyService economyService, PlayerLinkService playerLinkService) {
        this.economyService = economyService;
        this.playerLinkService = playerLinkService;
    }

    @Override
    public String getName() {
        return "economia";
    }

    @Override
    public String getDescription() {
        return "Administra la economía de Coins de los jugadores";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("dar", "Da Coins a un jugador")
                                .addOption(OptionType.USER, "usuario", "Jugador al que dar monedas", true)
                                .addOption(OptionType.INTEGER, "cantidad", "Cantidad de monedas a dar", true),
                        new SubcommandData("quitar", "Quita Coins a un jugador")
                                .addOption(OptionType.USER, "usuario", "Jugador al que quitar monedas", true)
                                .addOption(OptionType.INTEGER, "cantidad", "Cantidad de monedas a quitar", true)
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (!checkAdminPermission(event)) {
            return;
        }

        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
            return;
        }

        try {
            User targetUser = event.getOption("usuario").getAsUser();
            long cantidad = event.getOption("cantidad").getAsLong();

            Optional<PlayerProfile> profileOpt = playerLinkService.findByDiscordId(targetUser.getId());
            if (profileOpt.isEmpty()) {
                event.reply("❌ El usuario " + targetUser.getAsMention() + " no tiene una cuenta vinculada.")
                        .setEphemeral(true).queue();
                return;
            }

            PlayerProfile profile = profileOpt.get();

            switch (subcommand) {
                case "dar" -> handleDar(event, profile, cantidad, targetUser);
                case "quitar" -> handleQuitar(event, profile, cantidad, targetUser);
                default -> event.reply("❌ Subcomando no reconocido: " + subcommand)
                        .setEphemeral(true).queue();
            }
        } catch (InvalidAmountException e) {
            event.reply("❌ La cantidad debe ser positiva.").setEphemeral(true).queue();
        } catch (InsufficientBalanceException e) {
            event.reply("❌ Balance insuficiente. Balance actual: "
                    + formatBalance(e.getCurrentBalance()) + " Coins.")
                    .setEphemeral(true).queue();
        } catch (Exception e) {
            log.error("Error al ejecutar /economia {}: {}", event.getSubcommandName(), e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }

    private void handleDar(SlashCommandInteractionEvent event, PlayerProfile profile,
                           long cantidad, User targetUser) {
        String adminName = event.getUser().getName();
        CurrencyTransaction transaction = economyService.creditCoins(
                profile, cantidad, TransactionType.ADMIN_CREDIT,
                "Crédito admin por " + adminName);

        var embed = new EmbedBuilder()
                .setColor(new Color(0x2ECC71))
                .setTitle("✅ Coins Acreditadas")
                .addField("Jugador", targetUser.getAsMention(), true)
                .addField("Cantidad", "+" + formatBalance(cantidad) + " Coins", true)
                .addField("Nuevo balance", formatBalance(transaction.getBalanceAfter()) + " Coins", false)
                .build();

        event.replyEmbeds(embed).queue();
    }

    private void handleQuitar(SlashCommandInteractionEvent event, PlayerProfile profile,
                              long cantidad, User targetUser) {
        String adminName = event.getUser().getName();
        CurrencyTransaction transaction = economyService.debitCoins(
                profile, cantidad, TransactionType.ADMIN_DEBIT,
                "Débito admin por " + adminName);

        var embed = new EmbedBuilder()
                .setColor(new Color(0xE74C3C))
                .setTitle("✅ Coins Debitadas")
                .addField("Jugador", targetUser.getAsMention(), true)
                .addField("Cantidad", "-" + formatBalance(cantidad) + " Coins", true)
                .addField("Nuevo balance", formatBalance(transaction.getBalanceAfter()) + " Coins", false)
                .build();

        event.replyEmbeds(embed).queue();
    }

    /**
     * Checks if the member has administrator permissions.
     * Replies with an ephemeral error message if not.
     *
     * @param event the slash command interaction event
     * @return true if the member has admin permissions, false otherwise
     */
    private boolean checkAdminPermission(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null || !member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Se requieren permisos de administrador.")
                    .setEphemeral(true).queue();
            return false;
        }
        return true;
    }

    private String formatBalance(long amount) {
        NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);
        return numberFormat.format(amount);
    }
}
