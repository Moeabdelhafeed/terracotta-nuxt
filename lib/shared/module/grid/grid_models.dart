import '../list/list_models.dart' show GlobalEmptyAction;

// Re-export the types that grid + list share so callers can pull
// them off the grid module's barrel without crossing into list.
export '../list/list_models.dart'
    show
        EdgeFadeMode,
        EdgeFadeStyle,
        GlobalBulkAction,
        GlobalEmptyAction,
        GlobalListPage,
        GlobalListPhase,
        GroupHeaderMode,
        ListItemAnimation,
        PaginationMode,
        PaginationStyle,
        SelectionMode;

/// Convenience for the empty-state CTA — re-exposed in the grid
/// barrel so callers can build one without importing the list module.
typedef GlobalGridEmptyAction = GlobalEmptyAction;
