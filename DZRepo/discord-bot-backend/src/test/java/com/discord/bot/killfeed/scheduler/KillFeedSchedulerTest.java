package com.discord.bot.killfeed.scheduler;

import com.discord.bot.killfeed.model.PollResult;
import com.discord.bot.killfeed.service.KillFeedService;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.scheduling.annotation.Scheduled;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link KillFeedScheduler}.
 * Validates: Requirement 2.1 (poll cycle every 5 minutes), Requirement 8.4 (metrics logging).
 */
@ExtendWith(MockitoExtension.class)
class KillFeedSchedulerTest {

    @Mock
    private KillFeedService killFeedService;

    private KillFeedScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new KillFeedScheduler(killFeedService);
    }

    @Test
    void scheduledPoll_invokesPollAllConfigs() {
        PollResult result = new PollResult(3, 5, 5, 0);
        when(killFeedService.pollAllConfigs()).thenReturn(result);

        scheduler.scheduledPoll();

        verify(killFeedService, times(1)).pollAllConfigs();
    }

    @Test
    void scheduledPoll_handlesZeroConfigs() {
        PollResult result = new PollResult(0, 0, 0, 0);
        when(killFeedService.pollAllConfigs()).thenReturn(result);

        scheduler.scheduledPoll();

        verify(killFeedService).pollAllConfigs();
    }

    @Test
    void scheduledPoll_handlesResultWithErrors() {
        PollResult result = new PollResult(2, 3, 1, 1);
        when(killFeedService.pollAllConfigs()).thenReturn(result);

        scheduler.scheduledPoll();

        verify(killFeedService).pollAllConfigs();
    }

    @Test
    void scheduledPollMethod_hasScheduledAnnotationWithCorrectFixedRate() throws NoSuchMethodException {
        Method method = KillFeedScheduler.class.getMethod("scheduledPoll");
        Scheduled annotation = method.getAnnotation(Scheduled.class);

        assertNotNull(annotation, "@Scheduled annotation should be present on scheduledPoll()");
        assertEquals(300000, annotation.fixedRate(),
                "fixedRate should be 300000 ms (5 minutes)");
    }
}
