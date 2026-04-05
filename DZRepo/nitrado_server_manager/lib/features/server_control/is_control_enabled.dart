/// Returns whether server control buttons should be enabled for the given
/// [status].
///
/// Controls are disabled when the server is in a transitional state
/// ("restarting", "installing") because issuing new commands during those
/// phases is not meaningful.
///
/// Requirements: 3.5
bool isControlEnabled(String status) {
  switch (status) {
    case 'started':
    case 'stopped':
      return true;
    case 'restarting':
    case 'installing':
      return false;
    default:
      return false;
  }
}
