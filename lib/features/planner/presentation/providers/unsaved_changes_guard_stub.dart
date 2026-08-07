/// No-op on non-web platforms — there's no browser tab-close event to guard
/// against here.
void configureUnsavedChangesGuard(bool Function() hasUnsavedChanges) {}
