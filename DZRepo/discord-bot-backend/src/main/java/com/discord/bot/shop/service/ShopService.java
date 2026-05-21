package com.discord.bot.shop.service;

import com.discord.bot.economy.exception.InsufficientBalanceException;
import com.discord.bot.economy.exception.PlayerNotLinkedException;
import com.discord.bot.economy.model.PlayerProfile;
import com.discord.bot.economy.model.TransactionType;
import com.discord.bot.economy.repository.PlayerProfileRepository;
import com.discord.bot.economy.service.EconomyService;
import com.discord.bot.shop.model.Product;
import com.discord.bot.shop.model.ShopOrder;
import com.discord.bot.shop.repository.ProductRepository;
import com.discord.bot.shop.repository.ShopOrderRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class ShopService {

    private static final Logger log = LoggerFactory.getLogger(ShopService.class);

    private final ProductRepository productRepository;
    private final ShopOrderRepository shopOrderRepository;
    private final PlayerProfileRepository playerProfileRepository;
    private final EconomyService economyService;
    private final ItemSpawnService itemSpawnService;

    public ShopService(ProductRepository productRepository,
                       ShopOrderRepository shopOrderRepository,
                       PlayerProfileRepository playerProfileRepository,
                       EconomyService economyService,
                       ItemSpawnService itemSpawnService) {
        this.productRepository = productRepository;
        this.shopOrderRepository = shopOrderRepository;
        this.playerProfileRepository = playerProfileRepository;
        this.economyService = economyService;
        this.itemSpawnService = itemSpawnService;
    }

    public List<Product> getAvailableProducts() {
        return productRepository.findByAvailableTrue();
    }

    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }

    @Transactional
    public ShopOrder processPurchase(String discordId, Long productId, int quantity,
                                     double coordX, double coordY) {
        PlayerProfile profile = playerProfileRepository.findByDiscordId(discordId)
                .orElseThrow(() -> new PlayerNotLinkedException(
                        "No tienes una cuenta vinculada. Usa /vincular primero."));

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Producto no encontrado con ID: " + productId));

        if (!product.isAvailable()) {
            throw new IllegalStateException("El producto '" + product.getName() + "' no está disponible.");
        }

        long totalPrice = product.getPrice() * quantity;

        if (profile.getBalance() < totalPrice) {
            throw new InsufficientBalanceException(
                    "Balance insuficiente. Necesitas " + totalPrice + " TNT Coins pero tienes " + profile.getBalance(),
                    profile.getBalance(), totalPrice);
        }

        economyService.debitCoins(profile, totalPrice, TransactionType.SHOP_PURCHASE,
                "Compra: " + quantity + "x " + product.getName());

        ShopOrder order = new ShopOrder(discordId, profile.getDayzPlayerName(), product,
                quantity, totalPrice, coordX, coordY);
        ShopOrder saved = shopOrderRepository.save(order);

        log.info("Order #{} created: player='{}', product='{}', qty={}, total={}, coords=({}, {})",
                saved.getId(), profile.getDayzPlayerName(), product.getName(),
                quantity, totalPrice, coordX, coordY);

        // Upload event files immediately with all pending orders (including this one)
        try {
            List<ShopOrder> allPending = shopOrderRepository.findByStatusOrderByCreatedAtAsc("PENDING");
            itemSpawnService.uploadPendingOrders(allPending);
            log.info("Order #{} — uploaded event files with {} total pending orders.", saved.getId(), allPending.size());
        } catch (Exception e) {
            log.warn("Order #{} — failed to upload event files (will retry on restart): {}", saved.getId(), e.getMessage());
        }

        // Order stays PENDING — items will spawn on next server restart
        log.info("Order #{} queued for delivery via event system (next restart)", saved.getId());

        return saved;
    }

    public List<ShopOrder> getPendingOrders() {
        return shopOrderRepository.findByStatusOrderByCreatedAtAsc("PENDING");
    }

    /**
     * Prepares pending orders for delivery by uploading event files to the server.
     * Call this before a server restart.
     */
    @Transactional
    public void prepareDelivery() {
        List<ShopOrder> pending = getPendingOrders();
        itemSpawnService.uploadPendingOrders(pending);
        log.info("Prepared {} orders for delivery on next restart.", pending.size());
    }

    /**
     * Marks all pending orders as delivered and clears the event files.
     * Call this after a server restart when items have spawned.
     */
    @Transactional
    public void confirmDelivery() {
        List<ShopOrder> pending = getPendingOrders();
        for (ShopOrder order : pending) {
            order.setStatus("DELIVERED");
            shopOrderRepository.save(order);
        }
        itemSpawnService.uploadEmptyFiles();
        log.info("Confirmed delivery of {} orders and cleared event files.", pending.size());
    }

    @Transactional
    public void markOrderDelivered(Long orderId) {
        shopOrderRepository.findById(orderId).ifPresent(order -> {
            order.setStatus("DELIVERED");
            shopOrderRepository.save(order);
            log.info("Order #{} marked as DELIVERED", orderId);
        });
    }

    // ---- Product Management ----

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    @Transactional
    public Product createProduct(String name, String description, String category, long price) {
        return createProduct(name, description, category, price, null);
    }

    @Transactional
    public Product createProduct(String name, String description, String category, long price, String dayzClassName) {
        Product product = new Product(name, description, category, price);
        if (dayzClassName != null && !dayzClassName.isBlank()) {
            product.setDayzClassName(dayzClassName);
        }
        Product saved = productRepository.save(product);
        log.info("Product created: id={}, name='{}', category='{}', price={}, dayzClass='{}'",
                saved.getId(), name, category, price, dayzClassName);
        return saved;
    }

    @Transactional
    public Product editProduct(Long id, String name, Long price, Boolean available) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Producto no encontrado con ID: " + id));

        if (name != null && !name.isBlank()) {
            product.setName(name);
        }
        if (price != null) {
            product.setPrice(price);
        }
        if (available != null) {
            product.setAvailable(available);
        }

        Product saved = productRepository.save(product);
        log.info("Product edited: id={}, name='{}', price={}, available={}",
                saved.getId(), saved.getName(), saved.getPrice(), saved.isAvailable());
        return saved;
    }

    @Transactional
    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Producto no encontrado con ID: " + id));
        productRepository.delete(product);
        log.info("Product deleted: id={}, name='{}'", id, product.getName());
    }
}
