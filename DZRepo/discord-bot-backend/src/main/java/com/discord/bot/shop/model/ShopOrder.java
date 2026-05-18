package com.discord.bot.shop.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * JPA entity representing a shop order placed by a player.
 */
@Entity
@Table(name = "shop_orders")
public class ShopOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String discordId;

    @Column(nullable = false)
    private String dayzPlayerName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private long totalPrice;

    @Column(nullable = false)
    private double coordX;

    @Column(nullable = false)
    private double coordY;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private String status = "PENDING";

    protected ShopOrder() {}

    public ShopOrder(String discordId, String dayzPlayerName, Product product,
                     int quantity, long totalPrice, double coordX, double coordY) {
        this.discordId = discordId;
        this.dayzPlayerName = dayzPlayerName;
        this.product = product;
        this.quantity = quantity;
        this.totalPrice = totalPrice;
        this.coordX = coordX;
        this.coordY = coordY;
        this.createdAt = LocalDateTime.now();
        this.status = "PENDING";
    }

    public Long getId() { return id; }
    public String getDiscordId() { return discordId; }
    public String getDayzPlayerName() { return dayzPlayerName; }
    public Product getProduct() { return product; }
    public int getQuantity() { return quantity; }
    public long getTotalPrice() { return totalPrice; }
    public double getCoordX() { return coordX; }
    public double getCoordY() { return coordY; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
