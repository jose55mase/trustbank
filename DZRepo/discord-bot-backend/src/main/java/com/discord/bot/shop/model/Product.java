package com.discord.bot.shop.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity representing a product available in the shop.
 */
@Entity
@Table(name = "shop_products")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column
    private String description;

    @Column(nullable = false)
    private String category;

    @Column(name = "dayz_class_name")
    private String dayzClassName;

    @Column(nullable = false)
    private long price;

    @Column(nullable = false)
    private boolean available = true;

    protected Product() {}

    public Product(String name, String description, String category, long price) {
        this.name = name;
        this.description = description;
        this.category = category;
        this.price = price;
        this.available = true;
    }

    public Product(String name, String description, String category, long price, String dayzClassName) {
        this(name, description, category, price);
        this.dayzClassName = dayzClassName;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getDayzClassName() { return dayzClassName; }
    public void setDayzClassName(String dayzClassName) { this.dayzClassName = dayzClassName; }
    public long getPrice() { return price; }
    public void setPrice(long price) { this.price = price; }
    public boolean isAvailable() { return available; }
    public void setAvailable(boolean available) { this.available = available; }
}
