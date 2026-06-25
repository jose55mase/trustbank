package com.discord.bot.shop.command;

import com.discord.bot.command.SlashCommand;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.ShopService;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Admin command {@code /limpiar} to manually trigger cleanup of delivered shop orders.
 * Marks all PENDING orders as DELIVERED and removes their custom files from the server.
 */
@Component
public class LimpiarCommand implements SlashCommand {

    private static final Logger log = LoggerFactory.getLogger(LimpiarCommand.class);

    private final ShopService shopService;

    public LimpiarCommand(ShopService shopService) {
        this.shopService = shopService;
    }

    @Override
    public String getName() {
        return "limpiar";
    }

    @Override
    public String getDescription() {
        return "Limpia los pedidos entregados y elimina archivos del servidor (admin)";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (event.getMember() == null || !event.getMember().hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores pueden usar este comando.")
                    .setEphemeral(true).queue();
            return;
        }

        event.deferReply(true).queue();

        try {
            // First try DB-based cleanup
            List<ShopOrder> pending = shopService.getPendingOrders();

            if (!pending.isEmpty()) {
                log.info("[Limpiar] Cleaning {} pending orders from DB", pending.size());
                shopService.confirmDelivery();

                StringBuilder sb = new StringBuilder();
                sb.append("✅ **Limpieza completada (desde DB)**\n\n");
                sb.append("Pedidos limpiados: **").append(pending.size()).append("**\n");
                for (ShopOrder order : pending) {
                    sb.append(String.format("• #%d — %s (%dx %s)\n",
                            order.getId(), order.getDayzPlayerName(),
                            order.getQuantity(), order.getProduct().getName()));
                }
                event.getHook().editOriginal(sb.toString()).queue();
            } else {
                // No pending orders in DB — scan Nitrado for orphaned shop files
                log.info("[Limpiar] No pending orders in DB. Scanning Nitrado for orphaned shop files...");
                int cleaned = shopService.cleanOrphanedShopFiles();

                if (cleaned > 0) {
                    event.getHook().editOriginal(
                            "✅ **Limpieza completada**\n\n" +
                            "No había pedidos en la DB, pero se encontraron **" + cleaned +
                            "** archivos huérfanos en el servidor que fueron eliminados."
                    ).queue();
                } else {
                    event.getHook().editOriginal("📭 No hay pedidos pendientes ni archivos huérfanos para limpiar.").queue();
                }
            }

        } catch (Exception e) {
            log.error("[Limpiar] Error during cleanup: {}", e.getMessage(), e);
            event.getHook().editOriginal("❌ Error al limpiar: " + e.getMessage()).queue();
        }
    }
}
