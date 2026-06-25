package com.discord.bot.shop.command;

import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.service.PlayerLinkService;
import com.discord.bot.shop.model.PlayerPosition;
import com.discord.bot.shop.model.Product;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.service.PlayerPositionService;
import com.discord.bot.shop.service.ShopService;

import net.dv8tion.jda.api.EmbedBuilder;
import net.dv8tion.jda.api.entities.channel.concrete.TextChannel;
import net.dv8tion.jda.api.events.interaction.ModalInteractionEvent;
import net.dv8tion.jda.api.events.interaction.component.ButtonInteractionEvent;
import net.dv8tion.jda.api.events.interaction.component.StringSelectInteractionEvent;
import net.dv8tion.jda.api.hooks.ListenerAdapter;
import net.dv8tion.jda.api.interactions.components.ActionRow;
import net.dv8tion.jda.api.interactions.components.buttons.Button;
import net.dv8tion.jda.api.interactions.components.selections.StringSelectMenu;
import net.dv8tion.jda.api.interactions.components.text.TextInput;
import net.dv8tion.jda.api.interactions.components.text.TextInputStyle;
import net.dv8tion.jda.api.interactions.modals.Modal;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ShopInteractionListener extends ListenerAdapter {

    private static final Logger log = LoggerFactory.getLogger(ShopInteractionListener.class);
    private static final String ORDERS_CHANNEL_NAME = "pedidos-mercado";

    private final ShopService shopService;
    private final PlayerLinkService playerLinkService;
    private final PlayerPositionService playerPositionService;

    /**
     * Active shopping sessions: player has confirmed their position and can add products.
     * Key: discordId, Value: confirmed position + list of completed orders in this session
     */
    private final Map<String, ShoppingSession> activeSessions = new ConcurrentHashMap<>();

    public ShopInteractionListener(ShopService shopService,
                                   PlayerLinkService playerLinkService,
                                   PlayerPositionService playerPositionService) {
        this.shopService = shopService;
        this.playerLinkService = playerLinkService;
        this.playerPositionService = playerPositionService;
    }

    @Override
    public void onButtonInteraction(ButtonInteractionEvent event) {
        String buttonId = event.getComponentId();

        switch (buttonId) {
            case "shop_open_catalog" -> handleOpenCatalog(event);
            case "shop_buy_button" -> handleBuyButton(event);
            case "shop_add_product" -> handleAddProductButton(event);
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
    public void onStringSelectInteraction(StringSelectInteractionEvent event) {
        String menuId = event.getComponentId();

        if (menuId.equals("shop_position_select")) {
            handlePositionSelect(event);
        }
    }

    @Override
    public void onModalInteraction(ModalInteractionEvent event) {
        switch (event.getModalId()) {
            case "shop_add_product_modal" -> handleAddProductModal(event);
            case "product_add_modal" -> handleProductAddModal(event);
            case "product_edit_modal" -> handleProductEditModal(event);
            case "product_delete_modal" -> handleProductDeleteModal(event);
        }
    }

    // ---- Shop Flow ----

    private void handleOpenCatalog(ButtonInteractionEvent event) {
        String discordId = event.getUser().getId();

        // Validate player is linked before showing catalog
        Optional<PlayerProfile> profileOpt = playerLinkService.findByDiscordId(discordId);
        if (profileOpt.isEmpty()) {
            var embed = new EmbedBuilder()
                    .setColor(new Color(0xE74C3C))
                    .setTitle("🔗 Cuenta no vinculada")
                    .setDescription(
                            "Para usar la tienda necesitas vincular tu cuenta de Discord " +
                            "con tu nombre de jugador en DayZ.\n\n" +
                            "Usa el comando `/vincular` seguido de tu nombre de jugador.\n\n" +
                            "**Ejemplo:** `/vincular MiNombreDayZ`"
                    )
                    .setFooter("DZ Market • Vincula tu cuenta para comprar")
                    .build();

            event.replyEmbeds(embed).setEphemeral(true).queue();
            return;
        }

        List<Product> products = shopService.getAvailableProducts();

        if (products.isEmpty()) {
            event.reply("📭 No hay productos disponibles en este momento.")
                    .setEphemeral(true).queue();
            return;
        }

        StringBuilder catalog = new StringBuilder();
        for (Product p : products) {
            catalog.append(String.format("**ID %d** — %s\n", p.getId(), p.getName()));
            catalog.append(String.format("   💰 %d Coins", p.getPrice()));
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
        String discordId = event.getUser().getId();

        // Validate player is linked
        Optional<PlayerProfile> profileOpt = playerLinkService.findByDiscordId(discordId);
        if (profileOpt.isEmpty()) {
            event.reply("❌ Debes vincular tu cuenta primero con `/vincular` para poder comprar.")
                    .setEphemeral(true).queue();
            return;
        }

        String dayzName = profileOpt.get().getDayzPlayerName();

        // Defer while we fetch positions from logs
        event.deferReply(true).queue();

        // Fetch last 3 unique positions from logs
        List<PlayerPosition> positions = playerPositionService.getLastPositions(dayzName);

        if (positions.isEmpty()) {
            event.getHook().editOriginal(
                    "❌ No se encontraron posiciones recientes para tu jugador **" + dayzName + "**.\n" +
                    "Debes estar conectado al servidor para que podamos detectar tu ubicación."
            ).queue();
            return;
        }

        // Build select menu with positions
        StringSelectMenu.Builder menuBuilder = StringSelectMenu.create("shop_position_select")
                .setPlaceholder("📍 Selecciona dónde entregar tus pedidos")
                .setRequiredRange(1, 1);

        for (int i = 0; i < positions.size(); i++) {
            PlayerPosition pos = positions.get(i);
            String label = String.format("Posición %d — %s", i + 1, pos.timestamp());
            String description = String.format("X: %.1f | Z: %.1f | Altura: %.1f", pos.x(), pos.z(), pos.y());
            menuBuilder.addOption(label, String.valueOf(i), description);
        }

        // Store positions temporarily for the select handler
        activeSessions.put(discordId, new ShoppingSession(positions, null, new ArrayList<>()));

        var embed = new EmbedBuilder()
                .setColor(new Color(0xF39C12))
                .setTitle("📍 Confirma tu ubicación de entrega")
                .setDescription(
                        "Jugador: **" + dayzName + "**\n\n" +
                        "Estas son tus últimas posiciones detectadas en el servidor.\n" +
                        "Selecciona dónde quieres recibir tus pedidos.\n\n" +
                        "Una vez confirmada la ubicación, podrás agregar productos sin volver a seleccionar posición."
                )
                .setFooter("DZ Market • Paso 1: Confirmar ubicación")
                .build();

        event.getHook().editOriginalEmbeds(embed)
                .setComponents(ActionRow.of(menuBuilder.build()))
                .queue();
    }

    /**
     * Player confirmed their delivery position. Show the "session" embed with Add Product button.
     */
    private void handlePositionSelect(StringSelectInteractionEvent event) {
        String discordId = event.getUser().getId();

        ShoppingSession session = activeSessions.get(discordId);
        if (session == null || session.positions() == null) {
            event.reply("❌ Tu sesión de compra expiró. Usa el botón 🛒 Abrir Tienda de nuevo.")
                    .setEphemeral(true).queue();
            return;
        }

        int positionIndex;
        try {
            positionIndex = Integer.parseInt(event.getValues().get(0));
        } catch (NumberFormatException e) {
            event.reply("❌ Error al procesar la selección.").setEphemeral(true).queue();
            return;
        }

        if (positionIndex < 0 || positionIndex >= session.positions().size()) {
            event.reply("❌ Posición inválida.").setEphemeral(true).queue();
            return;
        }

        PlayerPosition selectedPosition = session.positions().get(positionIndex);

        // Update session with confirmed position
        activeSessions.put(discordId, new ShoppingSession(
                session.positions(), selectedPosition, new ArrayList<>()));

        // Show the shopping session embed with Add Product button
        var embed = buildSessionEmbed(discordId, selectedPosition, List.of());

        event.editMessage("")
                .setEmbeds(embed.build())
                .setComponents(ActionRow.of(
                        Button.success("shop_add_product", "➕ Agregar Producto"),
                        Button.secondary("shop_open_catalog", "📋 Ver Catálogo")
                ))
                .queue();
    }

    /**
     * Player clicks "Add Product" — show modal to enter product ID and quantity.
     */
    private void handleAddProductButton(ButtonInteractionEvent event) {
        String discordId = event.getUser().getId();

        ShoppingSession session = activeSessions.get(discordId);
        if (session == null || session.confirmedPosition() == null) {
            event.reply("❌ Tu sesión expiró. Usa el botón 🛒 Abrir Tienda para iniciar una nueva compra.")
                    .setEphemeral(true).queue();
            return;
        }

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

        Modal modal = Modal.create("shop_add_product_modal", "➕ Agregar Producto al Pedido")
                .addComponents(
                        ActionRow.of(productId),
                        ActionRow.of(quantity)
                )
                .build();

        event.replyModal(modal).queue();
    }

    /**
     * Process the Add Product modal — debit coins, create order, update session embed.
     */
    private void handleAddProductModal(ModalInteractionEvent event) {
        String discordId = event.getUser().getId();

        ShoppingSession session = activeSessions.get(discordId);
        if (session == null || session.confirmedPosition() == null) {
            event.reply("❌ Tu sesión expiró. Usa el botón 🛒 Abrir Tienda para iniciar una nueva compra.")
                    .setEphemeral(true).queue();
            return;
        }

        String productIdStr = event.getValue("product_id").getAsString().trim();
        String quantityStr = event.getValue("quantity").getAsString().trim();

        long productId;
        int quantity;

        try {
            productId = Long.parseLong(productIdStr);
            quantity = Integer.parseInt(quantityStr);
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

        // Defer — upload to Nitrado can take time
        event.deferReply(true).queue();

        PlayerPosition pos = session.confirmedPosition();

        try {
            ShopOrder order = shopService.processPurchase(
                    discordId, productId, quantity,
                    pos.x(), pos.y(), pos.z()
            );

            // Add order to session history
            List<OrderSummary> updatedOrders = new ArrayList<>(session.orders());
            updatedOrders.add(new OrderSummary(
                    order.getId(), order.getProduct().getName(),
                    order.getQuantity(), order.getTotalPrice()));

            activeSessions.put(discordId, new ShoppingSession(
                    session.positions(), session.confirmedPosition(), updatedOrders));

            // Reply with success + updated session
            var successEmbed = buildSessionEmbed(discordId, pos, updatedOrders);

            event.getHook().editOriginalEmbeds(successEmbed.build())
                    .setComponents(ActionRow.of(
                            Button.success("shop_add_product", "➕ Agregar Producto"),
                            Button.secondary("shop_open_catalog", "📋 Ver Catálogo")
                    ))
                    .queue();

            // Publish to orders channel
            publishOrderToChannel(event, order);

        } catch (Exception e) {
            log.error("Error processing purchase for user {}: {}", discordId, e.getMessage());
            event.getHook().editOriginal("❌ " + e.getMessage()).queue();
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
                .addField("Total Pagado", order.getTotalPrice() + " Coins", true)
                .addField("Coordenadas",
                        String.format("X: %.1f | Z: %.1f | Altura: %.1f",
                                order.getCoordX(), order.getCoordZ(), order.getCoordY()), false)
                .addField("Estado", "⏳ PENDIENTE", false)
                .setFooter("Pedido realizado")
                .setTimestamp(order.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant())
                .build();

        ordersChannel.sendMessageEmbeds(orderEmbed)
                .addActionRow(Button.success("shop_deliver_" + order.getId(), "✅ Marcar Entregado"))
                .queue();
    }

    /**
     * Builds the session embed showing confirmed position and list of orders placed.
     */
    private EmbedBuilder buildSessionEmbed(String discordId, PlayerPosition pos, List<OrderSummary> orders) {
        var embed = new EmbedBuilder()
                .setColor(new Color(0x2ECC71))
                .setTitle("🛒 Sesión de Compra Activa")
                .addField("📍 Ubicación de entrega",
                        String.format("X: %.1f | Z: %.1f | Altura: %.1f", pos.x(), pos.z(), pos.y()), false);

        if (orders.isEmpty()) {
            embed.setDescription("✅ Ubicación confirmada. Haz click en **➕ Agregar Producto** para comprar.");
        } else {
            StringBuilder orderList = new StringBuilder();
            long totalSpent = 0;
            for (OrderSummary o : orders) {
                orderList.append(String.format("• **#%d** — %dx %s (%d Coins)\n",
                        o.orderId(), o.quantity(), o.productName(), o.totalPrice()));
                totalSpent += o.totalPrice();
            }
            embed.addField("📦 Pedidos en esta sesión (" + orders.size() + ")", orderList.toString(), false);
            embed.addField("💰 Total gastado", totalSpent + " Coins", true);
            embed.setDescription("Puedes seguir agregando productos. Todos se entregarán en la misma ubicación.");
        }

        embed.setFooter("DZ Market • Los pedidos se entregan en el próximo restart");
        return embed;
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
                        ActionRow.of(TextInput.create("price", "Precio (Coins)", TextInputStyle.SHORT)
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
            sb.append(String.format("%s **ID %d** — %s\n   💰 %d Coins • 📁 %s\n",
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
                .addField("Precio", product.getPrice() + " Coins", true)
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
                    .addField("Precio", product.getPrice() + " Coins", true)
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

    // ---- Internal DTOs ----

    /**
     * Holds the active shopping session for a player.
     */
    private record ShoppingSession(
            List<PlayerPosition> positions,
            PlayerPosition confirmedPosition,
            List<OrderSummary> orders
    ) {}

    /**
     * Summary of a completed order within a session.
     */
    private record OrderSummary(long orderId, String productName, int quantity, long totalPrice) {}
}
