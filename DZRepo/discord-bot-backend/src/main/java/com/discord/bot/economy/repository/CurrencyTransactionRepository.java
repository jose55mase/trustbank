package com.discord.bot.economy.repository;

import com.discord.bot.economy.model.CurrencyTransaction;
import com.discord.bot.economy.model.PlayerProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Spring Data JPA repository for {@link CurrencyTransaction} entities.
 * Provides CRUD operations and custom query methods for retrieving
 * recent transactions per player and paginated global transaction history.
 */
public interface CurrencyTransactionRepository extends JpaRepository<CurrencyTransaction, Long> {

    List<CurrencyTransaction> findTop10ByPlayerProfileOrderByCreatedAtDesc(PlayerProfile profile);

    Page<CurrencyTransaction> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
