// Guards against losing an unsaved planner change when the browser tab is
// closed — something the autosave debounce alone can't prevent, since the
// browser can kill the page before an in-flight save request finishes.
//
// Web-only; a no-op on mobile/desktop where there's no such event.
export 'unsaved_changes_guard_stub.dart'
    if (dart.library.html) 'unsaved_changes_guard_web.dart';
