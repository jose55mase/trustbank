package com.discord.bot.shop.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.ShopService;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.OptionType;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.commands.build.SlashCommandData;
import net.dv8tion.jda.api.interactions.commands.build.SubcommandData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Discord command for managing shop deliveries via the DayZ event system.
 *
 * <p>Subcommands:
 * <ul>
 *   <li>{@code /entregas preparar} — Uploads pending orders to event files (run before restart)</li>
 *   <li>{@code /entregas confirmar} — Marks orders as delivered and clears event files (run after restart)</li>
 *   <li>{@code /entregas pendientes} — Shows list of pending orders</li>
 * </ul>
 */
@Component
public class EntregasCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(EntregasCommand.class);

    private final ShopService shopService;

    public EntregasCommand(ShopService shopService) {
        this.shopService = shopService;
    }

    @Override
    public String getName() {
        return "entregas";
    }

    @Override
    public String getDescription() {
        return "Gestionar entregas de la tienda (preparar/confirmar/pendientes)";
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (event.getMember() == null || !event.getMember().hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores pueden gestionar entregas.")
                    .setEphemeral(true).queue();
            return;
        }

        String subcommand = event.getSubcommandName();
        if (subcommand == null) {
            event.reply("❌ Usa un subcomando: preparar, confirmar, o pendientes.")
                    .setEphemeral(true).queue();
            return;
        }

        switch (subcommand) {
            case "preparar" -> handlePreparar(event);
            case "confirmar" -> handleConfirmar(event);
            case "pendientes" -> handlePendientes(event);
            default -> event.reply("❌ Subcomando no reconocido.").setEphemeral(true).queue();
        }
    }

    private void handlePreparar(SlashCommandInteractionEvent event) {
        event.deferReply().queue();

        try {
            List<ShopOrder> pending = shopService.getPendingOrders();
            if (pending.isEmpty()) {
                event.getHook().editOriginal("📭 No hay pedidos pendientes para preparar.").queue();
                return;
            }

            shopService.prepareDelivery();
            event.getHook().editOriginal(
                    "✅ **" + pending.size() + " pedidos** preparados para entrega.\n" +
                    "Los items aparecerán en el servidor después del próximo restart.\n" +
                    "Usa `/entregas confirmar` después del restart para marcarlos como entregados."
            ).queue();
        } catch (Exception e) {
            log.error("Error preparing deliveries: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Error al preparar entregas: " + e.getMessage()).queue();
        }
    }

    private void handleConfirmar(SlashCommandInteractionEvent event) {
        event.deferReply().queue();

        try {
            List<ShopOrder> pending = shopService.getPendingOrders();
            if (pending.isEmpty()) {
                event.getHook().editOriginal("📭 No hay pedidos pendientes para confirmar.").queue();
                return;
            }

            shopService.confirmDelivery();
            event.getHook().editOriginal(
                    "✅ **" + pending.size() + " pedidos** marcados como entregados.\n" +
                    "Los archivos de eventos han sido limpiados."
            ).queue();
        } catch (Exception e) {
            log.error("Error confirming deliveries: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Error al confirmar entregas: " + e.getMessage()).queue();
        }
    }

    private void handlePendientes(SlashCommandInteractionEvent event) {
        List<ShopOrder> pending = shopService.getPendingOrders();

        if (pending.isEmpty()) {
            event.reply("📭 No hay pedidos pendientes.").setEphemeral(true).queue();
            return;
        }

        StringBuilder sb = new StringBuilder();
        sb.append("📦 **Pedidos Pendientes (").append(pending.size()).append("):**\n\n");

        for (ShopOrder order : pending) {
            sb.append(String.format("**#%d** — %dx %s para **%s** en (X:%.0f, Z:%.0f, Alt:%.0f)\n",
                    order.getId(), order.getQuantity(), order.getProduct().getName(),
                    order.getDayzPlayerName(), order.getCoordX(), order.getCoordZ(), order.getCoordY()));
        }

        sb.append("\nUsa `/entregas preparar` antes del restart para subir los archivos.");

        event.reply(sb.toString()).setEphemeral(true).queue();
    }
}
