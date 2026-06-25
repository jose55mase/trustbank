package com.discord.bot.shop.command;

import com.discord.bot.command.SlashCommand;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.commands.build.CommandData;
import net.dv8tion.jda.api.interactions.commands.build.Commands;
import net.dv8tion.jda.api.interactions.components.buttons.Button;

import org.springframework.stereotype.Component;

import java.awt.Color;

@Component
public class ProductoCommand implements SlashCommand {

    @Override
    public String getName() {
        return "producto";
    }

    @Override
    public String getDescription() {
        return "Panel de gestión de productos de la tienda (solo admin)";
    }

    @Override
    public CommandData getCommandData() {
        return Commands.slash(getName(), getDescription());
    }

    @Override
    public void execute(SlashCommandInteractionEvent event) {
        if (!event.getMember().hasPermission(Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo los administradores pueden usar este comando.")
                    .setEphemeral(true).queue();
            return;
        }

        var embed = new EmbedBuilder()
                .setColor(new Color(0x9B59B6))
                .setTitle("⚙️ Gestión de Productos")
                .setDescription("Selecciona una acción para administrar el catálogo de la tienda.")
                .addField("➕ Agregar", "Crear un nuevo producto", false)
                .addField("✏️ Editar", "Modificar un producto existente", false)
                .addField("🗑️ Eliminar", "Eliminar un producto por ID", false)
                .addField("📋 Listar", "Ver todos los productos registrados", false)
                .setFooter("DZ Market • Admin Panel")
                .build();

        event.replyEmbeds(embed)
                .addActionRow(
                        Button.success("product_add", "➕ Agregar"),
                        Button.primary("product_edit", "✏️ Editar"),
                        Button.danger("product_delete", "🗑️ Eliminar"),
                        Button.secondary("product_list", "📋 Listar")
                )
                .setEphemeral(true)
                .queue();
    }
}
