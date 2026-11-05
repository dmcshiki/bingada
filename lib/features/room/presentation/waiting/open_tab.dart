import 'package:tokingo/features/room/presentation/waiting/open_tab_stub.dart'
    if (dart.library.js_interop) 'package:tokingo/features/room/presentation/waiting/open_tab_web.dart'
    as impl;

/// Opens [path] (app-relative) in a new browser tab. Returns false when not
/// supported (non-web), so the caller can fall back to in-app navigation.
bool openInNewTab(String path) => impl.openInNewTab(path);
