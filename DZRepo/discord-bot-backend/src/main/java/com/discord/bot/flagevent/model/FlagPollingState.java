package com.discord.bot.flagevent.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity tracking the polling state for incremental log processing.
 * Only one polling state per guild (unique constraint on guildId).
 */
@Entity
@Table(name = "flag_polling_state")
public class FlagPollingState {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String guildId;

    @Column(nullable = false)
    private int lastLineIndex;

    @Column(nullable = false)
    private String lastTimestamp;

    protected FlagPollingState() {}

    public FlagPollingState(String guildId, int lastLineIndex, String lastTimestamp) {
        this.guildId = guildId;
        this.lastLineIndex = lastLineIndex;
        this.lastTimestamp = lastTimestamp;
    }

    public Long getId() { return id; }

    public String getGuildId() { return guildId; }
    public void setGuildId(String guildId) { this.guildId = guildId; }

    public int getLastLineIndex() { return lastLineIndex; }
    public void setLastLineIndex(int lastLineIndex) { this.lastLineIndex = lastLineIndex; }

    public String getLastTimestamp() { return lastTimestamp; }
    public void setLastTimestamp(String lastTimestamp) { this.lastTimestamp = lastTimestamp; }
}
