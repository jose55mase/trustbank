package com.discord.bot.command;

import com.discord.bot.BotInitializer;
import com.discord.bot.killfeed.model.NotificationConfig;
import com.discord.bot.killfeed.store.NotificationConfigStore;
import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.ShopService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.List;

/**
 * Slash command that restarts a DayZ server hosted on Nitrado.
 * Sends a notification to the configured channel with delivery info.
 */
@Component
public class RestartCommand extends AbstractServerCommand {

    private static final Logger log = LoggerFactory.getLogger(RestartCommand.class);

    private final ShopService shopService;
    private final NotificationConfigStore notificationConfigStore;
    private final BotInitializer botInitializer;

    public RestartCommand(NitradoApiClient nitradoApiClient,
                          ShopService shopService,
                          NotificationConfigStore notificationConfigStore,
                          @Lazy BotInitializer botInitializer) {
        super(nitradoApiClient);
        this.shopService = shopService;
        this.notificationConfigStore = notificationConfigStore;
        this.botInitializer = botInitializer;
    }

    @Override
    public String getName() {
        return "restart";
    }

    @Override
    public String getDescription() {
        return "Reinicia el servidor DayZ (solo administradores)";
    }

    @Override
    protected ServerAction getAction() {
        return ServerAction.RESTART;
    }

    @Override
    protected String getSuccessMessage(String serverName) {
        return "El servidor '" + serverName + "' se está reiniciando.";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        Member member = event.getMember();
        if (member == null) {
            event.reply("❌ Este comando solo está disponible en servidores de Discord.")
                    .setEphemeral(true).queue();
            return;
        }

        if (!member.hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ No tienes permisos para ejecutar este comando. Se requiere rol de administrador.")
                    .setEphemeral(true).queue();
            return;
        }

        event.deferReply().queue();

        try {
            List<GameServerDto> servers = nitradoApiClient.getServers();

            if (servers.isEmpty()) {
                event.getHook().editOriginal("❌ No se encontraron servidores DayZ disponibles.").queue();
            } else if (servers.size() == 1) {
                GameServerDto server = servers.get(0);
                nitradoApiClient.serverAction(server.id(), getAction());

                // Mark pending orders as delivered in DB (files stay on server until it boots)
                String deliveryMsg = "";
                List<ShopOrder> pending = shopService.getPendingOrders();
                if (!pending.isEmpty()) {
                    deliveryMsg = "\n📦 " + pending.size() + " pedido(s) se entregarán al iniciar el servidor.";
                }

                event.getHook().editOriginal("✅ " + getSuccessMessage(server.name()) + deliveryMsg).queue();

                // Send notification to configured channel
                sendRestartNotification(event, server.name(), pending.size());
            } else {
                StringBuilder sb = new StringBuilder();
                sb.append("Hay varios servidores disponibles:\n");
                for (int i = 0; i < servers.size(); i++) {
                    GameServerDto s = servers.get(i);
                    String statusEmoji = "started".equalsIgnoreCase(s.status()) ? "🟢" : "🔴";
                    sb.append(i + 1).append(". ")
                            .append(statusEmoji).append(" ")
                            .append(s.name())
                            .append(" (ID: ").append(s.id()).append(") - ")
                            .append(s.status()).append("\n");
                }
                event.getHook().editOriginal(sb.toString().trim()).queue();
            }
        } catch (Exception e) {
            log.error("Error ejecutando restart: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Error: " + e.getMessage()).queue();
        }
    }

    private void sendRestartNotification(SlashCommandInteractionEvent event, String serverName, int pendingOrders) {
        if (event.getGuild() == null) return;

        String guildId = event.getGuild().getId();
        NotificationConfig config = notificationConfigStore.getConfig(guildId).orElse(null);
        if (config == null) return;

        TextChannel channel = botInitializer.getJda().getTextChannelById(config.channelId());
        if (channel == null) return;

        var embed = new EmbedBuilder()
                .setColor(new Color(0xF39C12))
                .setTitle("🔄 Servidor Reiniciando")
                .setDescription("El servidor **" + serverName + "** se está reiniciando.")
                .addField("📦 Pedidos en cola", pendingOrders > 0
                        ? pendingOrders + " pedido(s) se entregarán al iniciar"
                        : "No hay pedidos pendientes", false)
                .setFooter("Los items aparecerán en el mapa cuando el servidor inicie")
                .build();

        channel.sendMessageEmbeds(embed).queue(
                msg -> log.info("Restart notification sent to channel {}", config.channelId()),
                err -> log.warn("Failed to send restart notification: {}", err.getMessage())
        );
    }
}
