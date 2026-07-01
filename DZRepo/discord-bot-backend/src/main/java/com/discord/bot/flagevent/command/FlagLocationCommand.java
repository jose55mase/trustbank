package com.discord.bot.flagevent.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.flagevent.config.FlagEventProperties;
import com.discord.bot.flagevent.model.FlagLocation;
import com.discord.bot.flagevent.service.FlagEventService;

import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionMapping;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * Slash command {@code /flag-location} for configuring the monitored flag location.
 *
 * <p>Provides subcommands:</p>
 * <ul>
 *   <li>{@code /flag-location set x:<decimal> z:<decimal> [tolerance:<decimal>]} — sets the flag location</li>
 *   <li>{@code /flag-location get} — retrieves the current flag location</li>
 * </ul>
 */
@Component
public class FlagLocationCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(FlagLocationCommand.class);

    private static final double COORD_MIN = 0.0;
    private static final double COORD_MAX = 15360.0;
    private static final double TOLERANCE_MIN = 1.0;
    private static final double TOLERANCE_MAX = 1000.0;

    private final FlagEventService flagEventService;
    private final FlagEventProperties flagEventProperties;

    public FlagLocationCommand(FlagEventService flagEventService, FlagEventProperties flagEventProperties) {
        this.flagEventService = flagEventService;
        this.flagEventProperties = flagEventProperties;
    }

    @Override
    public String getName() {
        return "flag-location";
    }

    @Override
    public String getDescription() {
        return "Configure the monitored flag location";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription())
                .addSubcommands(
                        new SubcommandData("set", "Set the flag location coordinates")
                                .addOption(OptionType.NUMBER, "x", "X coordinate (0-15360)", true)
                                .addOption(OptionType.NUMBER, "z", "Z coordinate (0-15360)", true)
                                .addOption(OptionType.NUMBER, "tolerance", "Position tolerance in meters (1-1000)", false),
                        new SubcommandData("get", "Get the current flag location")
                );
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        String subcommand = event.getSubcommandName();

        if (subcommand == null) {
            event.reply("❌ Unknown subcommand.").setEphemeral(true).queue();
            return;
        }

        switch (subcommand) {
            case "set" -> handleSet(event);
            case "get" -> handleGet(event);
            default -> event.reply("❌ Unknown subcommand: " + subcommand)
                    .setEphemeral(true).queue();
        }
    }

    private void handleSet(SlashCommandInteractionEvent event) {
        double x = event.getOption("x", OptionMapping::getAsDouble);
        double z = event.getOption("z", OptionMapping::getAsDouble);

        // Validate X coordinate range
        if (x < COORD_MIN || x > COORD_MAX) {
            event.reply("❌ Invalid X coordinate. Must be a numeric value between 0 and 15360.")
                    .setEphemeral(true).queue();
            return;
        }

        // Validate Z coordinate range
        if (z < COORD_MIN || z > COORD_MAX) {
            event.reply("❌ Invalid Z coordinate. Must be a numeric value between 0 and 15360.")
                    .setEphemeral(true).queue();
            return;
        }

        // Determine tolerance: use provided value or default
        OptionMapping toleranceOption = event.getOption("tolerance");
        double tolerance;
        if (toleranceOption != null) {
            tolerance = toleranceOption.getAsDouble();
            if (tolerance < TOLERANCE_MIN || tolerance > TOLERANCE_MAX) {
                event.reply("❌ Invalid tolerance. Must be a numeric value between 1 and 1000.")
                        .setEphemeral(true).queue();
                return;
            }
        } else {
            tolerance = flagEventProperties.getDefaultTolerance();
        }

        String guildId = flagEventProperties.getGuildId();
        FlagLocation saved = flagEventService.setFlagLocation(guildId, x, z, tolerance);

        event.reply(String.format("✅ Flag location set to X=%.2f, Z=%.2f with tolerance=%.2f meters.",
                        saved.getCoordX(), saved.getCoordZ(), saved.getTolerance()))
                .setEphemeral(true).queue();
    }

    private void handleGet(SlashCommandInteractionEvent event) {
        String guildId = flagEventProperties.getGuildId();
        Optional<FlagLocation> locationOpt = flagEventService.getFlagLocation(guildId);

        if (locationOpt.isEmpty()) {
            event.reply("ℹ️ No flag location has been set.")
                    .setEphemeral(true).queue();
            return;
        }

        FlagLocation location = locationOpt.get();
        event.reply(String.format("📍 Flag location: X=%.2f, Z=%.2f | Tolerance=%.2f meters",
                        location.getCoordX(), location.getCoordZ(), location.getTolerance()))
                .setEphemeral(true).queue();
    }
}
