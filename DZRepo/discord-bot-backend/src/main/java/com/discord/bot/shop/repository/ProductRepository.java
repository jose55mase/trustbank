package com.discord.bot.shop.repository;

import com.discord.bot.shop.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByAvailableTrue();
    List<Product> findByCategoryIgnoreCaseAndAvailableTrue(String category);
}
