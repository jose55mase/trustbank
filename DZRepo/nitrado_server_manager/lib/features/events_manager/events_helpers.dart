import '../../shared/models/spawn_event.dart';

/// Returns `true` if the event is active (active == 1),
/// `false` if inactive (active == 0).
///
/// Used by Property 13: Mapeo estado activo/inactivo de eventos.
bool isEventActive(SpawnEvent event) {
  return event.active == 1;
}
