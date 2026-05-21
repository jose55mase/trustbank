package com.discord.bot.shop.command;

import com.discord.bot.shop.model.Product;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.ShopService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.ModalInteractionEvent;
import net.dv8tion.jda.api.events.interaction.component.ButtonInteractionEvent;
import net.dv8tion.jda.api.hooks.ListenerAdapter;
import net.dv8tion.jda.api.interactions.components.ActionRow;
import net.dv8tion.jda.api.interactions.components.buttons.Button;
import net.dv8tion.jda.api.interactions.components.text.TextInput;
import net.dv8tion.jda.api.interactions.components.text.TextInputStyle;
import net.dv8tion.jda.api.interactions.modals.Modal;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.List;

@Component
public class ShopInteractionListener extends ListenerAdapter {

    private static final Logger log = LoggerFactory.getLogger(ShopInteractionListener.class);
    private static final String ORDERS_CHANNEL_NAME = "pedidos-mercado";

    private final ShopService shopService;

    public ShopInteractionListener(ShopService shopService) {
        this.shopService = shopService;
    }

    @Override
    public void onButtonInteraction(ButtonInteractionEvent event) {
        String buttonId = event.getComponentId();

        switch (buttonId) {
            case "shop_open_catalog" -> handleOpenCatalog(event);
            case "shop_buy_button" -> handleBuyButton(event);
            case "product_add" -> handleProductAddButton(event);
            case "product_edit" -> handleProductEditButton(event);
            case "product_delete" -> handleProductDeleteButton(event);
            case "product_list" -> handleProductList(event);
            default -> {
                if (buttonId.startsWith("shop_deliver_")) {
                    handleDeliverButton(event, buttonId);
                }
            }
        }
    }

    @Override
    public void onModalInteraction(ModalInteractionEvent event) {
        switch (event.getModalId()) {
            case "shop_purchase_modal" -> handlePurchaseModal(event);
            case "product_add_modal" -> handleProductAddModal(event);
            case "product_edit_modal" -> handleProductEditModal(event);
            case "product_delete_modal" -> handleProductDeleteModal(event);
        }
    }

    private void handleOpenCatalog(ButtonInteractionEvent event) {
        List<Product> products = shopService.getAvailableProducts();

        if (products.isEmpty()) {
            event.reply("📭 No hay productos disponibles en este momento.")
                    .setEphemeral(true).queue();
            return;
        }

        StringBuilder catalog = new StringBuilder();
        for (Product p : products) {
            catalog.append(String.format("**ID %d** — %s\n", p.getId(), p.getName()));
            catalog.append(String.format("   💰 %d TNT Coins", p.getPrice()));
            if (p.getDescription() != null && !p.getDescription().isBlank()) {
                catalog.append(String.format(" • %s", p.getDescription()));
            }
            catalog.append(String.format(" • 📁 %s\n\n", p.getCategory()));
        }

        var embed = new EmbedBuilder()
                .setColor(new Color(0x3498DB))
                .setTitle("📋 Catálogo de Productos")
                .setDescription(catalog.toString())
                .setFooter("Haz click en 🛍️ Comprar para realizar tu pedido")
                .build();

        event.replyEmbeds(embed)
                .addActionRow(Button.primary("shop_buy_button", "🛍️ Comprar"))
                .setEphemeral(true)
                .queue();
    }

    private void handleBuyButton(ButtonInteractionEvent event) {
        TextInput productId = TextInput.create("product_id", "ID del Producto", TextInputStyle.SHORT)
                .setPlaceholder("Ej: 1")
                .setRequired(true)
                .setMinLength(1)
                .setMaxLength(10)
                .build();

        TextInput quantity = TextInput.create("quantity", "Cantidad", TextInputStyle.SHORT)
                .setPlaceholder("Ej: 2")
                .setRequired(true)
                .setMinLength(1)
                .setMaxLength(5)
                .build();

        TextInput coordX = TextInput.create("coord_x", "Coordenada X", TextInputStyle.SHORT)
                .setPlaceholder("Ej: 4523.5")
                .setRequired(true)
                .setMinLength(1)
                .setMaxLength(10)
                .build();

        TextInput coordY = TextInput.create("coord_y", "Coordenada Y", TextInputStyle.SHORT)
                .setPlaceholder("Ej: 8912.3")
                .setRequired(true)
                .setMinLength(1)
                .setMaxLength(10)
                .build();

        Modal modal = Modal.create("shop_purchase_modal", "🛍️ Realizar Compra")
                .addComponents(
                        ActionRow.of(productId),
                        ActionRow.of(quantity),
                        ActionRow.of(coordX),
                        ActionRow.of(coordY)
                )
                .build();

        event.replyModal(modal).queue();
    }

    private void handlePurchaseModal(ModalInteractionEvent event) {
        String discordId = event.getUser().getId();

        String productIdStr = event.getValue("product_id").getAsString().trim();
        String quantityStr = event.getValue("quantity").getAsString().trim();
        String coordXStr = event.getValue("coord_x").getAsString().trim();
        String coordYStr = event.getValue("coord_y").getAsString().trim();

        long productId;
        int quantity;
        double coordX, coordY;

        try {
            productId = Long.parseLong(productIdStr);
            quantity = Integer.parseInt(quantityStr);
            coordX = Double.parseDouble(coordXStr);
            coordY = Double.parseDouble(coordYStr);
        } catch (NumberFormatException e) {
            event.reply("❌ Los valores ingresados no son válidos. Asegúrate de usar números.")
                    .setEphemeral(true).queue();
            return;
        }

        if (quantity <= 0) {
            event.reply("❌ La cantidad debe ser mayor a 0.")
                    .setEphemeral(true).queue();
            return;
        }

        try {
            ShopOrder order = shopService.processPurchase(discordId, productId, quantity, coordX, coordY);

            var confirmEmbed = new EmbedBuilder()
                    .setColor(new Color(0x2ECC71))
                    .setTitle("✅ Compra Exitosa")
                    .addField("Producto", order.getProduct().getName(), true)
                    .addField("Cantidad", String.valueOf(order.getQuantity()), true)
                    .addField("Total", order.getTotalPrice() + " TNT Coins", true)
                    .addField("Coordenadas", String.format("X: %.1f | Y: %.1f", order.getCoordX(), order.getCoordY()), false)
                    .addField("Pedido #", String.valueOf(order.getId()), true)
                    .addField("Estado", "⏳ PENDIENTE (se entrega en próximo restart)", true)
                    .setFooter("Tu pedido se entregará en el próximo reinicio del servidor")
                    .build();

            event.replyEmbeds(confirmEmbed).setEphemeral(true).queue();

            publishOrderToChannel(event, order);

        } catch (Exception e) {
            log.error("Error processing purchase for user {}: {}", discordId, e.getMessage());
            event.reply("❌ " + e.getMessage()).setEphemeral(true).queue();
        }
    }

    private void publishOrderToChannel(ModalInteractionEvent event, ShopOrder order) {
        if (event.getGuild() == null) return;

        List<TextChannel> channels = event.getGuild().getTextChannelsByName(ORDERS_CHANNEL_NAME, true);
        if (channels.isEmpty()) {
            log.warn("Canal '{}' no encontrado en el servidor. No se pudo publicar el pedido #{}",
                    ORDERS_CHANNEL_NAME, order.getId());
            return;
        }

        TextChannel ordersChannel = channels.get(0);

        var orderEmbed = new EmbedBuilder()
                .setColor(new Color(0xE67E22))
                .setTitle("📦 Nuevo Pedido #" + order.getId())
                .addField("Jugador", order.getDayzPlayerName(), true)
                .addField("Discord", "<@" + order.getDiscordId() + ">", true)
                .addField("Producto", order.getProduct().getName(), true)
                .addField("Cantidad", String.valueOf(order.getQuantity()), true)
                .addField("Total Pagado", order.getTotalPrice() + " TNT Coins", true)
                .addField("Coordenadas", String.format("X: %.1f | Y: %.1f", order.getCoordX(), order.getCoordY()), false)
                .addField("Estado", "⏳ PENDIENTE", false)
                .setFooter("Pedido realizado")
                .setTimestamp(order.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant())
                .build();

        ordersChannel.sendMessageEmbeds(orderEmbed)
                .addActionRow(Button.success("shop_deliver_" + order.getId(), "✅ Marcar Entregado"))
                .queue();
    }

    // ---- Product Management Handlers ----

    private void handleProductAddButton(ButtonInteractionEvent event) {
        if (!event.getMember().hasPermission(net.dv8tion.jda.api.Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores.").setEphemeral(true).queue();
            return;
        }

        Modal modal = Modal.create("product_add_modal", "➕ Agregar Producto")
                .addComponents(
                        ActionRow.of(TextInput.create("name", "Nombre", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: AK-47").setRequired(true).build()),
                        ActionRow.of(TextInput.create("price", "Precio (TNT Coins)", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: 500").setRequired(true).build()),
                        ActionRow.of(TextInput.create("category", "Categoría", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: Armas, Comida, Ropa").setRequired(true).build()),
                        ActionRow.of(TextInput.create("dayz_class", "DayZ ClassName", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: AKM, M4A1, AliceBag_Black").setRequired(true).build()),
                        ActionRow.of(TextInput.create("description", "Descripción", TextInputStyle.PARAGRAPH)
                                .setPlaceholder("Descripción del producto").setRequired(false).build())
                )
                .build();

        event.replyModal(modal).queue();
    }

    private void handleProductEditButton(ButtonInteractionEvent event) {
        if (!event.getMember().hasPermission(net.dv8tion.jda.api.Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores.").setEphemeral(true).queue();
            return;
        }

        Modal modal = Modal.create("product_edit_modal", "✏️ Editar Producto")
                .addComponents(
                        ActionRow.of(TextInput.create("id", "ID del Producto", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: 1").setRequired(true).build()),
                        ActionRow.of(TextInput.create("name", "Nuevo Nombre (dejar vacío para no cambiar)", TextInputStyle.SHORT)
                                .setRequired(false).build()),
                        ActionRow.of(TextInput.create("price", "Nuevo Precio (dejar vacío para no cambiar)", TextInputStyle.SHORT)
                                .setRequired(false).build()),
                        ActionRow.of(TextInput.create("available", "Disponible (si/no, vacío para no cambiar)", TextInputStyle.SHORT)
                                .setPlaceholder("si o no").setRequired(false).build())
                )
                .build();

        event.replyModal(modal).queue();
    }

    private void handleProductDeleteButton(ButtonInteractionEvent event) {
        if (!event.getMember().hasPermission(net.dv8tion.jda.api.Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores.").setEphemeral(true).queue();
            return;
        }

        Modal modal = Modal.create("product_delete_modal", "🗑️ Eliminar Producto")
                .addComponents(
                        ActionRow.of(TextInput.create("id", "ID del Producto a eliminar", TextInputStyle.SHORT)
                                .setPlaceholder("Ej: 1").setRequired(true).build())
                )
                .build();

        event.replyModal(modal).queue();
    }

    private void handleProductList(ButtonInteractionEvent event) {
        if (!event.getMember().hasPermission(net.dv8tion.jda.api.Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo administradores.").setEphemeral(true).queue();
            return;
        }

        List<Product> products = shopService.getAllProducts();

        if (products.isEmpty()) {
            event.reply("📭 No hay productos registrados.").setEphemeral(true).queue();
            return;
        }

        StringBuilder sb = new StringBuilder();
        for (Product p : products) {
            String status = p.isAvailable() ? "✅" : "❌";
            sb.append(String.format("%s **ID %d** — %s\n   💰 %d TNT Coins • 📁 %s\n",
                    status, p.getId(), p.getName(), p.getPrice(), p.getCategory()));
            if (p.getDescription() != null && !p.getDescription().isBlank()) {
                sb.append(String.format("   📝 %s\n", p.getDescription()));
            }
            sb.append("\n");
        }

        var embed = new EmbedBuilder()
                .setColor(new Color(0x9B59B6))
                .setTitle("📋 Todos los Productos")
                .setDescription(sb.toString())
                .setFooter("✅ = Disponible | ❌ = No disponible")
                .build();

        event.replyEmbeds(embed).setEphemeral(true).queue();
    }

    private void handleProductAddModal(ModalInteractionEvent event) {
        String name = event.getValue("name").getAsString().trim();
        String priceStr = event.getValue("price").getAsString().trim();
        String category = event.getValue("category").getAsString().trim();
        String description = event.getValue("description") != null
                ? event.getValue("description").getAsString().trim() : "";
        String dayzClassName = event.getValue("dayz_class") != null
                ? event.getValue("dayz_class").getAsString().trim() : "";

        long price;
        try {
            price = Long.parseLong(priceStr);
        } catch (NumberFormatException e) {
            event.reply("❌ El precio debe ser un número válido.").setEphemeral(true).queue();
            return;
        }

        if (price <= 0) {
            event.reply("❌ El precio debe ser mayor a 0.").setEphemeral(true).queue();
            return;
        }

        Product product = shopService.createProduct(name, description, category, price, dayzClassName);

        var embed = new EmbedBuilder()
                .setColor(new Color(0x2ECC71))
                .setTitle("✅ Producto Creado")
                .addField("ID", String.valueOf(product.getId()), true)
                .addField("Nombre", product.getName(), true)
                .addField("Precio", product.getPrice() + " TNT Coins", true)
                .addField("Categoría", product.getCategory(), true)
                .addField("DayZ Class", product.getDayzClassName() != null ? product.getDayzClassName() : "N/A", true)
                .addField("Descripción", description.isBlank() ? "Sin descripción" : description, false)
                .build();

        event.replyEmbeds(embed).setEphemeral(true).queue();
    }

    private void handleProductEditModal(ModalInteractionEvent event) {
        String idStr = event.getValue("id").getAsString().trim();
        String name = event.getValue("name") != null ? event.getValue("name").getAsString().trim() : "";
        String priceStr = event.getValue("price") != null ? event.getValue("price").getAsString().trim() : "";
        String availableStr = event.getValue("available") != null ? event.getValue("available").getAsString().trim() : "";

        long id;
        try {
            id = Long.parseLong(idStr);
        } catch (NumberFormatException e) {
            event.reply("❌ El ID debe ser un número válido.").setEphemeral(true).queue();
            return;
        }

        Long price = null;
        if (!priceStr.isBlank()) {
            try {
                price = Long.parseLong(priceStr);
                if (price <= 0) {
                    event.reply("❌ El precio debe ser mayor a 0.").setEphemeral(true).queue();
                    return;
                }
            } catch (NumberFormatException e) {
                event.reply("❌ El precio debe ser un número válido.").setEphemeral(true).queue();
                return;
            }
        }

        Boolean available = null;
        if (!availableStr.isBlank()) {
            if (availableStr.equalsIgnoreCase("si") || availableStr.equalsIgnoreCase("sí")) {
                available = true;
            } else if (availableStr.equalsIgnoreCase("no")) {
                available = false;
            } else {
                event.reply("❌ El campo disponible debe ser 'si' o 'no'.").setEphemeral(true).queue();
                return;
            }
        }

        try {
            Product product = shopService.editProduct(id, name.isBlank() ? null : name, price, available);

            var embed = new EmbedBuilder()
                    .setColor(new Color(0xF39C12))
                    .setTitle("✏️ Producto Editado")
                    .addField("ID", String.valueOf(product.getId()), true)
                    .addField("Nombre", product.getName(), true)
                    .addField("Precio", product.getPrice() + " TNT Coins", true)
                    .addField("Disponible", product.isAvailable() ? "✅ Sí" : "❌ No", true)
                    .build();

            event.replyEmbeds(embed).setEphemeral(true).queue();
        } catch (IllegalArgumentException e) {
            event.reply("❌ " + e.getMessage()).setEphemeral(true).queue();
        }
    }

    private void handleProductDeleteModal(ModalInteractionEvent event) {
        String idStr = event.getValue("id").getAsString().trim();

        long id;
        try {
            id = Long.parseLong(idStr);
        } catch (NumberFormatException e) {
            event.reply("❌ El ID debe ser un número válido.").setEphemeral(true).queue();
            return;
        }

        try {
            shopService.deleteProduct(id);
            event.reply("✅ Producto #" + id + " eliminado correctamente.").setEphemeral(true).queue();
        } catch (IllegalArgumentException e) {
            event.reply("❌ " + e.getMessage()).setEphemeral(true).queue();
        }
    }

    // ---- Order Handlers ----

    private void handleDeliverButton(ButtonInteractionEvent event, String buttonId) {
        if (!event.getMember().hasPermission(net.dv8tion.jda.api.Permission.ADMINISTRATOR)) {
            event.reply("❌ Solo los administradores pueden marcar pedidos como entregados.")
                    .setEphemeral(true).queue();
            return;
        }

        String orderIdStr = buttonId.replace("shop_deliver_", "");
        try {
            Long orderId = Long.parseLong(orderIdStr);
            shopService.markOrderDelivered(orderId);

            event.reply("✅ Pedido #" + orderId + " marcado como **ENTREGADO**")
                    .queue();

            event.getMessage().editMessageComponents().queue();
        } catch (Exception e) {
            log.error("Error marking order as delivered: {}", e.getMessage());
            event.reply("❌ Error al actualizar el pedido.").setEphemeral(true).queue();
        }
    }
}
