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
    ADMIN_DEBIT
}
