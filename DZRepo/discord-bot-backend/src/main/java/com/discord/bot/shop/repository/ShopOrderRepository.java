package com.discord.bot.shop.repository;

import com.discord.bot.shop.model.ShopOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ShopOrderRepository extends JpaRepository<ShopOrder, Long> {
    List<ShopOrder> findByDiscordIdOrderByCreatedAtDesc(String discordId);
    List<ShopOrder> findByStatusOrderByCreatedAtAsc(String status);
    
    /**
     * Fetches pending orders with their associated Product eagerly loaded.
     * Use this when you need to access product details outside a transaction.
     */
    @Query("SELECT o FROM ShopOrder o JOIN FETCH o.product WHERE o.status = :status ORDER BY o.createdAt ASC")
    List<ShopOrder> findByStatusWithProductOrderByCreatedAtAsc(@Param("status") String status);
}
