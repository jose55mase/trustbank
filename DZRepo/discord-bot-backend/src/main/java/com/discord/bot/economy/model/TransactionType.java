package com.discord.bot.economy.model;

/**
 * Types of currency transactions in the economy system.
 */
public enum TransactionType {
    /** Coins earned by killing a zombie with a melee weapon. */
    ZOMBIE_KILL_REWARD,
    /** Coins credited by an administrator. */
    ADMIN_CREDIT,
    /** Coins debited by an administrator. */
    ADMIN_DEBIT,
    /** Coins sent to another player via /transferir. */
    PLAYER_TRANSFER_SENT,
    /** Coins received from another player via /transferir. */
    PLAYER_TRANSFER_RECEIVED,
    /** Coins spent purchasing a product from the shop. */
    SHOP_PURCHASE
}
