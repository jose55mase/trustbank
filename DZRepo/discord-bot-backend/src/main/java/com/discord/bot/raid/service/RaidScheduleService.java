package com.discord.bot.raid.service;

import com.discord.bot.BotInitializer;
import com.discord.bot.nitrado.service.NitradoApiClient;
import com.discord.bot.raid.dto.RaidScheduleUpdateDto;
import com.discord.bot.raid.model.RaidSchedule;
import com.discord.bot.raid.repository.RaidScheduleRepository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import net.dv8tion.jda.api.JDA;
import net.dv8tion.jda.api.entities.channel.middleman.GuildChannel;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Service for managing raid schedules and updating Discord channel names
 * to reflect the current raid status.
 */
@Service
public class RaidScheduleService {

    private static final Logger log = LoggerFactory.getLogger(RaidScheduleService.class);

    /** Channel name when raid is INACTIVE (red circle). */
    public static final String CHANNEL_NAME_RAID_OFF = "💥-raid-status-🔴";

    /** Channel name when raid is ACTIVE (green circle). */
    public static final String CHANNEL_NAME_RAID_ON = "💥-raid-status-🟢";

    private final RaidScheduleRepository raidScheduleRepository;
    private final BotInitializer botInitializer;
    private final NitradoApiClient nitradoClient;
    private final ObjectMapper objectMapper;

    @Value("${shop.nitrado.service-id:0}")
    private int serviceId;

    @Value("${shop.nitrado.gameplay-path:/dayzOffline.enoch/cfggameplay.json}")
    private String gameplayFilePath;

    public RaidScheduleService(RaidScheduleRepository raidScheduleRepository,
                               @Lazy BotInitializer botInitializer,
                               NitradoApiClient nitradoClient) {
        this.raidScheduleRepository = raidScheduleRepository;
        this.botInitializer = botInitializer;
        this.nitradoClient = nitradoClient;
        this.objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
    }

    /**
     * Gets the raid schedule configuration for a guild.
     * Creates a default configuration if none exists.
     *
     * @param guildId the Discord guild ID
     * @return the raid schedule configuration
     */
    @Transactional
    public RaidSchedule getOrCreateSchedule(String guildId) {
        return raidScheduleRepository.findByGuildId(guildId)
                .orElseGet(() -> raidScheduleRepository.save(new RaidSchedule(guildId)));
    }

    /**
     * Updates the raid schedule configuration for a guild.
     *
     * @param guildId the Discord guild ID
     * @param dto the update data
     * @return the updated raid schedule
     */
    @Transactional
    public RaidSchedule updateSchedule(String guildId, RaidScheduleUpdateDto dto) {
        RaidSchedule schedule = getOrCreateSchedule(guildId);

        if (dto.getStatusChannelId() != null) {
            schedule.setStatusChannelId(dto.getStatusChannelId());
        }
        if (dto.getRaidStartTime() != null) {
            schedule.setRaidStartTime(dto.getRaidStartTime());
        }
        if (dto.getRaidEndTime() != null) {
            schedule.setRaidEndTime(dto.getRaidEndTime());
        }
        if (dto.getEnabled() != null) {
            schedule.setEnabled(dto.getEnabled());
        }

        RaidSchedule saved = raidScheduleRepository.save(schedule);

        // Immediately check and update status if enabled
        if (saved.isEnabled()) {
            checkAndUpdateRaidStatus(saved);
        }

        return saved;
    }

    /**
     * Gets all enabled raid schedules.
     *
     * @return list of enabled raid schedules
     */
    public List<RaidSchedule> getAllEnabledSchedules() {
        return raidScheduleRepository.findByEnabledTrue();
    }

    /**
     * Checks if raid should be active based on current time and schedule,
     * updates the Discord channel name and modifies cfggameplay.json on Nitrado
     * to enable/disable base damage accordingly.
     *
     * <p>When raid is ACTIVE (🟢): disableBaseDamage=false, disableContainerDamage=false
     * <p>When raid is INACTIVE (🔴): disableBaseDamage=true, disableContainerDamage=true
     *
     * @param schedule the raid schedule to check
     */
    @Transactional
    public void checkAndUpdateRaidStatus(RaidSchedule schedule) {
        if (!schedule.isEnabled() || schedule.getStatusChannelId() == null) {
            return;
        }

        boolean shouldBeActive = isRaidTimeActive(schedule);
        boolean statusChanged = shouldBeActive != schedule.isRaidActive();

        if (statusChanged) {
            schedule.setRaidActive(shouldBeActive);
            raidScheduleRepository.save(schedule);
            updateChannelName(schedule);
            updateGameplayBaseDamage(shouldBeActive);
            log.info("Raid status changed for guild {}: now {} | baseDamage={}", 
                    schedule.getGuildId(), 
                    shouldBeActive ? "ACTIVE 🟢" : "INACTIVE 🔴",
                    shouldBeActive ? "ENABLED" : "DISABLED");
        }
    }

    /**
     * Determines if the current time falls within the raid time window.
     * Supports schedules that cross midnight (e.g., 22:00 to 06:00).
     *
     * @param schedule the raid schedule
     * @return true if raid should be active
     */
    public boolean isRaidTimeActive(RaidSchedule schedule) {
        if (schedule.getRaidStartTime() == null || schedule.getRaidEndTime() == null) {
            return false;
        }

        LocalDateTime now = LocalDateTime.now();
        LocalTime currentTime = now.toLocalTime();
        LocalTime startTime = schedule.getRaidStartTime().toLocalTime();
        LocalTime endTime = schedule.getRaidEndTime().toLocalTime();

        // Handle schedules that cross midnight
        if (startTime.isAfter(endTime)) {
            // e.g., 22:00 to 06:00 - raid is active if current time is after start OR before end
            return !currentTime.isBefore(startTime) || !currentTime.isAfter(endTime);
        } else {
            // e.g., 10:00 to 18:00 - raid is active if current time is between start and end
            return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
        }
    }

    /**
     * Updates the Discord channel name to reflect the current raid status.
     *
     * @param schedule the raid schedule with the channel to update
     */
    public void updateChannelName(RaidSchedule schedule) {
        JDA jda = botInitializer.getJda();
        if (jda == null) {
            log.warn("JDA not available, cannot update channel name");
            return;
        }

        String channelId = schedule.getStatusChannelId();
        if (channelId == null || channelId.isBlank()) {
            log.warn("No status channel configured for guild {}", schedule.getGuildId());
            return;
        }

        String newName = schedule.isRaidActive() ? CHANNEL_NAME_RAID_ON : CHANNEL_NAME_RAID_OFF;

        try {
            GuildChannel channel = jda.getGuildChannelById(channelId);
            if (channel == null) {
                log.warn("Channel {} not found for guild {}", channelId, schedule.getGuildId());
                return;
            }

            // Check if name already matches to avoid rate limits
            if (channel.getName().equals(newName)) {
                log.debug("Channel name already matches: {}", newName);
                return;
            }

            channel.getManager().setName(newName).queue(
                    success -> log.info("Updated raid status channel to: {}", newName),
                    error -> log.error("Failed to update channel name: {}", error.getMessage())
            );
        } catch (Exception e) {
            log.error("Error updating channel name for guild {}: {}", 
                    schedule.getGuildId(), e.getMessage(), e);
        }
    }

    /**
     * Forces an immediate update of the channel name and gameplay config for a schedule.
     * Used when the schedule is first configured or manually triggered.
     *
     * @param guildId the guild ID
     */
    @Transactional
    public void forceUpdateStatus(String guildId) {
        Optional<RaidSchedule> scheduleOpt = raidScheduleRepository.findByGuildId(guildId);
        if (scheduleOpt.isEmpty()) {
            return;
        }

        RaidSchedule schedule = scheduleOpt.get();
        if (!schedule.isEnabled()) {
            return;
        }

        boolean shouldBeActive = isRaidTimeActive(schedule);
        schedule.setRaidActive(shouldBeActive);
        raidScheduleRepository.save(schedule);
        updateChannelName(schedule);
        updateGameplayBaseDamage(shouldBeActive);
    }

    /**
     * Downloads cfggameplay.json from Nitrado, modifies the GeneralData section
     * to enable or disable base/container damage, then re-uploads it.
     *
     * <p>When raid is ACTIVE: structures CAN be damaged (disableBaseDamage=false, disableContainerDamage=false)
     * <p>When raid is INACTIVE: structures are PROTECTED (disableBaseDamage=true, disableContainerDamage=true)
     *
     * @param raidActive true if raid is now active (bases can be damaged)
     */
    @SuppressWarnings("unchecked")
    private void updateGameplayBaseDamage(boolean raidActive) {
        try {
            log.info("[Raid] Updating cfggameplay.json: raidActive={}, disableBaseDamage={}", 
                    raidActive, !raidActive);

            String content = nitradoClient.downloadFile(serviceId, gameplayFilePath);
            Map<String, Object> gameplay = objectMapper.readValue(content, new TypeReference<>() {});

            // Get or create GeneralData section
            Map<String, Object> generalData = (Map<String, Object>) gameplay.get("GeneralData");
            if (generalData == null) {
                generalData = new LinkedHashMap<>();
                gameplay.put("GeneralData", generalData);
            }

            // When raid is ACTIVE → bases CAN be damaged → disableBaseDamage = false
            // When raid is INACTIVE → bases are PROTECTED → disableBaseDamage = true
            generalData.put("disableBaseDamage", !raidActive);
            generalData.put("disableContainerDamage", !raidActive);

            String updatedContent = objectMapper.writeValueAsString(gameplay);
            nitradoClient.uploadFile(serviceId, gameplayFilePath, updatedContent);

            log.info("[Raid] ✅ cfggameplay.json updated: disableBaseDamage={}, disableContainerDamage={}", 
                    !raidActive, !raidActive);

        } catch (JsonProcessingException e) {
            log.error("[Raid] ❌ Error parsing cfggameplay.json: {}", e.getMessage(), e);
        } catch (Exception e) {
            log.error("[Raid] ❌ Error updating cfggameplay.json on Nitrado: {}", e.getMessage(), e);
        }

        // Also update messages.xml to show/hide raid messages
        updateMessagesXml(raidActive);
    }

    /**
     * Updates the messages.xml file on Nitrado to toggle raid-related messages.
     *
     * <p>When raid is ACTIVE:
     * - Hides the "Raiding only during raid hours" rule (comments it out)
     * - Shows an elegant "Raid Active" announcement message
     *
     * <p>When raid is INACTIVE:
     * - Shows the raid rule messages again
     * - Hides the "Raid Active" announcement
     *
     * Uses marker comments (RAID_RULES_START/END and RAID_ACTIVE_START/END)
     * to locate the sections to toggle.
     */
    private void updateMessagesXml(boolean raidActive) {
        try {
            String messagesPath = gameplayFilePath.substring(0, gameplayFilePath.lastIndexOf('/')) + "/db/messages.xml";
            log.info("[Raid] Updating messages.xml: raidActive={}, path={}", raidActive, messagesPath);

            String content = nitradoClient.downloadFile(serviceId, messagesPath);

            String updatedContent;
            if (raidActive) {
                updatedContent = setRaidActiveMessages(content);
            } else {
                updatedContent = setRaidInactiveMessages(content);
            }

            nitradoClient.uploadFile(serviceId, messagesPath, updatedContent);
            log.info("[Raid] ✅ messages.xml updated successfully");

        } catch (Exception e) {
            log.error("[Raid] ❌ Error updating messages.xml: {}", e.getMessage(), e);
        }
    }

    /**
     * Modifies messages.xml for RAID ACTIVE state:
     * - Comments out the raid rules (between RAID_RULES_START and RAID_RULES_END)
     * - Inserts elegant raid active announcement messages
     */
    private String setRaidActiveMessages(String content) {
        // Replace raid rules section with commented-out version
        String raidRulesContent = extractBetweenMarkers(content, "RAID_RULES_START", "RAID_RULES_END");
        if (raidRulesContent != null && !raidRulesContent.trim().startsWith("<!--")) {
            String commentedRules = "<!--\n" + raidRulesContent + "    -->\n";
            content = replaceBetweenMarkers(content, "RAID_RULES_START", "RAID_RULES_END", commentedRules);
        }

        // Insert raid active messages
        String raidActiveMessages = "\n"
                + "    <message>\n"
                + "        <delay>5</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</text>\n"
                + "    </message>\n"
                + "    <message>\n"
                + "        <delay>5</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>⚔ ░▒▓ R A I D   A C T I V O ▓▒░ ⚔</text>\n"
                + "    </message>\n"
                + "    <message>\n"
                + "        <delay>5</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>💥 Las bases PUEDEN ser raideadas 💥</text>\n"
                + "    </message>\n"
                + "    <message>\n"
                + "        <delay>5</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</text>\n"
                + "    </message>\n"
                + "    <message>\n"
                + "        <delay>6</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>⚔ ░▒▓ R A I D   A C T I V E ▓▒░ ⚔</text>\n"
                + "    </message>\n"
                + "    <message>\n"
                + "        <delay>6</delay>\n"
                + "        <repeat>15</repeat>\n"
                + "        <onconnect>1</onconnect>\n"
                + "        <text>💥 Bases CAN be raided now 💥</text>\n"
                + "    </message>\n";

        content = replaceBetweenMarkers(content, "RAID_ACTIVE_START", "RAID_ACTIVE_END", raidActiveMessages);

        return content;
    }

    /**
     * Modifies messages.xml for RAID INACTIVE state:
     * - Uncomments the raid rules (between RAID_RULES_START and RAID_RULES_END)
     * - Removes the raid active announcement messages
     */
    private String setRaidInactiveMessages(String content) {
        // Uncomment raid rules
        String raidRulesContent = extractBetweenMarkers(content, "RAID_RULES_START", "RAID_RULES_END");
        if (raidRulesContent != null && raidRulesContent.trim().startsWith("<!--")) {
            // Remove comment markers
            String uncommented = raidRulesContent
                    .replace("<!--\n", "")
                    .replace("<!--", "")
                    .replace("    -->\n", "")
                    .replace("-->", "");
            content = replaceBetweenMarkers(content, "RAID_RULES_START", "RAID_RULES_END", uncommented);
        }

        // Clear raid active messages (leave empty between markers)
        content = replaceBetweenMarkers(content, "RAID_ACTIVE_START", "RAID_ACTIVE_END", "\n");

        return content;
    }

    /**
     * Extracts content between two marker comments in XML.
     * Markers are expected as: &lt;!-- MARKER_NAME --&gt;
     */
    private String extractBetweenMarkers(String content, String startMarker, String endMarker) {
        String startTag = "<!-- " + startMarker + " -->";
        String endTag = "<!-- " + endMarker + " -->";

        int startIdx = content.indexOf(startTag);
        int endIdx = content.indexOf(endTag);

        if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
            return null;
        }

        return content.substring(startIdx + startTag.length(), endIdx);
    }

    /**
     * Replaces content between two marker comments in XML.
     */
    private String replaceBetweenMarkers(String content, String startMarker, String endMarker, String replacement) {
        String startTag = "<!-- " + startMarker + " -->";
        String endTag = "<!-- " + endMarker + " -->";

        int startIdx = content.indexOf(startTag);
        int endIdx = content.indexOf(endTag);

        if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
            log.warn("[Raid] Markers not found: {} / {}", startMarker, endMarker);
            return content;
        }

        return content.substring(0, startIdx + startTag.length())
                + replacement
                + content.substring(endIdx);
    }
}
