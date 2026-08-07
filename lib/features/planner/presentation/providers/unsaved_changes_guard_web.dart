// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

html.EventListener? _listener;

/// Registers a `beforeunload` handler that shows the browser's native
/// "leave site? changes may not be saved" confirmation whenever
/// [hasUnsavedChanges] returns true at the moment the tab is closing.
///
/// Safe to call more than once — replaces the previous handler rather than
/// stacking listeners.
void configureUnsavedChangesGuard(bool Function() hasUnsavedChanges) {
  final previous = _listener;
  if (previous != null) {
    html.window.removeEventListener('beforeunload', previous);
  }
  void listener(html.Event event) {
    if (hasUnsavedChanges()) {
      event.preventDefault();
      // Legacy requirement for the browser to actually show the prompt —
      // modern browsers ignore the custom string and show their own text.
      (event as html.BeforeUnloadEvent).returnValue = '';
    }
  }

  _listener = listener;
  html.window.addEventListener('beforeunload', listener);
}
