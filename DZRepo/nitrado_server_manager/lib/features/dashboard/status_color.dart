import 'package:flutter/material.dart';

/// Maps a server status string to its corresponding indicator color.
///
/// - "started" → green (online)
/// - "stopped" → red (offline)
/// - "restarting", "installing" → yellow (transitioning)
/// - Any other status → yellow (unknown/transitioning)
///
/// Requirements: 2.5, 10.5
Color statusColor(String status) {
  switch (status) {
    case 'started':
      return Colors.green;
    case 'stopped':
      return Colors.red;
    case 'restarting':
    case 'installing':
      return Colors.yellow;
    default:
      return Colors.yellow;
  }
}
