package com.discord.bot.gamelogs.dto;

import com.discord.bot.gamelogs.model.GameLogCategory;
import com.discord.bot.gamelogs.model.GameLogEvent;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class GameLogEventMapperTest {

    @Test
    void toDto_mapsAllFieldsCorrectly() {
        var event = new GameLogEvent(
            "14:32:05",
            GameLogCategory.CONNECTION,
            "SurvivorJoe",
            "Player \"SurvivorJoe\" is connected (id=abc123)",
            Map.of("playerId", "abc123"),
            0
        );

        GameLogEventDto dto = GameLogEventMapper.toDto(event);

        assertEquals("14:32:05", dto.timestamp());
        assertEquals("connection", dto.category());
        assertEquals("SurvivorJoe", dto.playerName());
        assertEquals("Player \"SurvivorJoe\" is connected (id=abc123)", dto.message());
        assertEquals(Map.of("playerId", "abc123"), dto.details());
    }

    @Test
    void toDto_convertsPlayerKillCategoryToSnakeCase() {
        var event = new GameLogEvent(
            "15:00:00",
            GameLogCategory.PLAYER_KILL,
            "Killer99",
            "Player killed",
            Map.of("weapon", "M4A1"),
            1
        );

        GameLogEventDto dto = GameLogEventMapper.toDto(event);

        assertEquals("player_kill", dto.category());
    }

    @Test
    void toDto_convertsZombieKillCategoryToSnakeCase() {
        var event = new GameLogEvent(
            "15:01:00",
            GameLogCategory.ZOMBIE_KILL,
            "Hunter42",
            "Zombie killed",
            Map.of("zombieType", "ZmbM_CitizenASkinny"),
            2
        );

        GameLogEventDto dto = GameLogEventMapper.toDto(event);

        assertEquals("zombie_kill", dto.category());
    }

    @Test
    void toDto_convertsAllCategoriesToLowercase() {
        for (GameLogCategory category : GameLogCategory.values()) {
            var event = new GameLogEvent("12:00:00", category, "Player", "msg", Map.of(), 0);
            GameLogEventDto dto = GameLogEventMapper.toDto(event);

            assertEquals(dto.category(), dto.category().toLowerCase(),
                "Category should be lowercase for " + category);
        }
    }

    @Test
    void toDto_excludesLineIndexFromDto() {
        var event = new GameLogEvent(
            "14:32:05",
            GameLogCategory.UNKNOWN,
            "",
            "Some unknown line",
            Map.of("rawLine", "14:32:05 | Some unknown line"),
            42
        );

        GameLogEventDto dto = GameLogEventMapper.toDto(event);

        // DTO should not expose lineIndex — it's an internal detail
        assertNotNull(dto.timestamp());
        assertNotNull(dto.category());
        assertNotNull(dto.playerName());
        assertNotNull(dto.message());
        assertNotNull(dto.details());
    }

    @Test
    void toDtoList_convertsAllEvents() {
        var events = List.of(
            new GameLogEvent("14:00:00", GameLogCategory.CONNECTION, "Player1", "connected", Map.of(), 0),
            new GameLogEvent("14:01:00", GameLogCategory.CHAT, "Player2", "hello", Map.of(), 1),
            new GameLogEvent("14:02:00", GameLogCategory.DISCONNECTION, "Player1", "disconnected", Map.of(), 2)
        );

        List<GameLogEventDto> dtos = GameLogEventMapper.toDtoList(events);

        assertEquals(3, dtos.size());
        assertEquals("connection", dtos.get(0).category());
        assertEquals("chat", dtos.get(1).category());
        assertEquals("disconnection", dtos.get(2).category());
    }

    @Test
    void toDtoList_emptyListReturnsEmptyList() {
        List<GameLogEventDto> dtos = GameLogEventMapper.toDtoList(List.of());

        assertTrue(dtos.isEmpty());
    }

    @Test
    void toDto_convertsHitCategory() {
        var event = new GameLogEvent("16:00:00", GameLogCategory.HIT, "Player1", "hit", Map.of(), 0);

        GameLogEventDto dto = GameLogEventMapper.toDto(event);

        assertEquals("hit", dto.category());
    }
}
