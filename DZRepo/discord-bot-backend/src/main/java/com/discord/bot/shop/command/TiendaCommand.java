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
public class TiendaCommand implements SlashCommand {

    @Override
    public String getName() {
        return "tienda";
    }

    @Override
    public String getDescription() {
        return "Configura el canal de la tienda con el botón de compra";
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

        // Check bot permissions in this channel
        var selfMember = event.getGuild().getSelfMember();
        var channel = event.getGuildChannel();
        if (!selfMember.hasPermission(channel, Permission.VIEW_CHANNEL, Permission.MESSAGE_SEND, Permission.MESSAGE_EMBED_LINKS)) {
            event.reply("❌ El bot no tiene permisos suficientes en este canal.\n" +
                    "Necesita: **Ver Canal**, **Enviar Mensajes**, **Insertar Enlaces**.")
                    .setEphemeral(true).queue();
            return;
        }

        var embed = new EmbedBuilder()
                .setColor(new Color(0xF1C40F))
                .setTitle("🏪 DZ Market")
                .setDescription("¡Bienvenido a la tienda del servidor!\n\n"
                        + "Haz click en el botón de abajo para ver el catálogo de productos "
                        + "y realizar tu compra.\n\n"
                        + "💰 Moneda: **Coins**\n"
                        + "📦 Los pedidos serán entregados en las coordenadas que indiques.")
                .setFooter("DZ Market • DayZ")
                .build();

        event.getChannel().sendMessageEmbeds(embed)
                .addActionRow(Button.success("shop_open_catalog", "🛒 Abrir Tienda"))
                .queue();

        event.reply("✅ Mensaje de tienda publicado en este canal.")
                .setEphemeral(true).queue();
    }
}
