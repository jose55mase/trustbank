package com.discord.bot.killfeed.store;

import com.discord.bot.killfeed.model.NotificationConfig;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class NotificationConfigStore {

    private final ConcurrentHashMap<String, NotificationConfig> configs = new ConcurrentHashMap<>();

    public void saveConfig(NotificationConfig config) {
        configs.put(config.guildId(), config);
    }

    public Optional<NotificationConfig> getConfig(String guildId) {
        return Optional.ofNullable(configs.get(guildId));
    }

    public void removeConfig(String guildId) {
        configs.remove(guildId);
    }
}
