package com.discord.bot.flagevent.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "flagevent")
public class FlagEventProperties {

    private int pollIntervalSeconds = 30;

    private int nitradoServiceId = 0;

    private String guildId = "";

    private double defaultTolerance = 10.0;

    public int getPollIntervalSeconds() {
        return pollIntervalSeconds;
    }

    public void setPollIntervalSeconds(int pollIntervalSeconds) {
        this.pollIntervalSeconds = pollIntervalSeconds;
    }

    public int getNitradoServiceId() {
        return nitradoServiceId;
    }

    public void setNitradoServiceId(int nitradoServiceId) {
        this.nitradoServiceId = nitradoServiceId;
    }

    public String getGuildId() {
        return guildId;
    }

    public void setGuildId(String guildId) {
        this.guildId = guildId;
    }

    public double getDefaultTolerance() {
        return defaultTolerance;
    }

    public void setDefaultTolerance(double defaultTolerance) {
        this.defaultTolerance = defaultTolerance;
    }
}
