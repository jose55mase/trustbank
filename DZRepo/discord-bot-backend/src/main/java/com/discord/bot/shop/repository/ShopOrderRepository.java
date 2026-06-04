package com.discord.bot.shop.repository;

import com.discord.bot.shop.model.ShopOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ShopOrderRepository extends JpaRepository<ShopOrder, Long> {
    List<ShopOrder> findByDiscordIdOrderByCreatedAtDesc(String discordId);
    List<ShopOrder> findByStatusOrderByCreatedAtAsc(String status);
}
