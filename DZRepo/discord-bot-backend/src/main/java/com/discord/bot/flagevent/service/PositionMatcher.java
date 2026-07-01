package com.discord.bot.flagevent.service;

import com.discord.bot.flagevent.model.FlagEvent;
import com.discord.bot.flagevent.model.FlagLocation;
import org.springframework.stereotype.Component;

/**
 * Pure computation component for 2D Euclidean distance checks.
 * Compares flag event positions against a configured location using only X and Z coordinates.
 * Y coordinates are completely ignored.
 */
@Component
public class PositionMatcher {

    /**
     * Returns the 2D Euclidean distance between two points using only X and Z coordinates.
     *
     * @param x1 first point X coordinate
     * @param z1 first point Z coordinate
     * @param x2 second point X coordinate
     * @param z2 second point Z coordinate
     * @return the 2D Euclidean distance
     */
    public double distance2D(double x1, double z1, double x2, double z2) {
        return Math.sqrt((x1 - x2) * (x1 - x2) + (z1 - z2) * (z1 - z2));
    }

    /**
     * Checks if the event flag position matches the configured location
     * within the given tolerance. Only X and Z coordinates are compared;
     * Y coordinates are completely ignored.
     *
     * @param event    the flag event containing flag position
     * @param location the configured flag location with tolerance
     * @return true if the 2D distance between event flag position and location is ≤ tolerance
     */
    public boolean matches(FlagEvent event, FlagLocation location) {
        double distance = distance2D(event.flagX(), event.flagZ(), location.getCoordX(), location.getCoordZ());
        return distance <= location.getTolerance();
    }
}
