package com.discord.bot.shop.model;

/**
 * Represents a player's position in the DayZ world.
 * Coordinates are stored in the JSON object spawner format: [X, Y, Z]
 * where X and Z are horizontal coordinates and Y is height/altitude.
 *
 * @param x         horizontal coordinate (east-west)
 * @param y         altitude/height
 * @param z         horizontal coordinate (north-south)
 * @param timestamp the timestamp from the log when this position was recorded (HH:mm:ss)
 */
public record PlayerPosition(
        double x,
        double y,
        double z,
        String timestamp
) {

    /**
     * Calculates the 2D horizontal distance to another position (ignoring altitude).
     */
    public double distanceTo(PlayerPosition other) {
        double dx = this.x - other.x;
        double dz = this.z - other.z;
        return Math.sqrt(dx * dx + dz * dz);
    }

    /**
     * Returns a formatted display string for Discord embeds.
     */
    public String toDisplayString() {
        return String.format("X: %.1f | Z: %.1f (Altura: %.1f) — %s", x, z, y, timestamp);
    }
}
