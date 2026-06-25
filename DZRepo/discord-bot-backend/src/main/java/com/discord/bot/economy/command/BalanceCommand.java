package com.discord.bot.economy.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.service.EconomyService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.text.NumberFormat;
import java.util.Locale;

/**
 * Slash command {@code /balance} that displays the player's current Coins balance.
 *
 * <p>Shows an embed with the formatted balance (thousands separator).
 * If the user has no linked account, an ephemeral error message is returned.</p>
 */
@Component
public class BalanceCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(BalanceCommand.class);

    private final EconomyService economyService;

    public BalanceCommand(EconomyService economyService) {
        this.economyService = economyService;
    }

    @Override
    public String getName() {
        return "balance";
    }

    @Override
    public String getDescription() {
        return "Muestra tu balance de Coins";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String discordId = event.getUser().getId();

        try {
            long balance = economyService.getBalance(discordId);

            NumberFormat numberFormat = NumberFormat.getIntegerInstance(Locale.US);
            String formattedBalance = numberFormat.format(balance);

            var embed = new EmbedBuilder()
                    .setColor(new Color(0xF1C40F))
                    .setTitle("💰 Balance de Coins")
                    .addField("Balance actual", formattedBalance + " Coins", false)
                    .build();

            event.replyEmbeds(embed).queue();
        } catch (PlayerNotLinkedException e) {
            event.reply("❌ No tienes una cuenta vinculada. Debes vincular tu cuenta primero usando `/vincular`.")
                    .setEphemeral(true).queue();
        } catch (Exception e) {
            log.error("Error al consultar balance para Discord ID {}: {}", discordId, e.getMessage(), e);
            event.reply("❌ Ocurrió un error interno. Intenta de nuevo.")
                    .setEphemeral(true).queue();
        }
    }
}
