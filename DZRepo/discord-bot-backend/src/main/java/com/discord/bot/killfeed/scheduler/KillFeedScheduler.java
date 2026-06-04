package com.discord.bot.killfeed.scheduler;

import com.discord.bot.killfeed.model.PollResult;
import com.discord.bot.killfeed.service.KillFeedService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Scheduled task that periodically polls all active kill feed configurations.
 *
 * <p>Runs every 5 minutes (300,000 ms) using Spring's {@code @Scheduled} support.
 * After each poll cycle, logs the metrics from the {@link PollResult}.</p>
 */
@Component
public class KillFeedScheduler {

    private static final Logger log = LoggerFactory.getLogger(KillFeedScheduler.class);

    private final KillFeedService killFeedService;

    public KillFeedScheduler(KillFeedService killFeedService) {
        this.killFeedService = killFeedService;
    }

    /**
     * Executes the kill feed poll cycle every 5 minutes.
     * Invokes {@link KillFeedService#pollAllConfigs()} and logs the resulting metrics.
     */
    @Scheduled(fixedRate = 300000)
    public void scheduledPoll() {
        log.info("Starting kill feed poll cycle");

        PollResult result = killFeedService.pollAllConfigs();

        log.info("Kill feed poll cycle completed — configs processed: {}, new events found: {}, embeds published: {}, errors: {}",
                result.configsProcessed(),
                result.newEventsFound(),
                result.embedsPublished(),
                result.errors());
    }
}
