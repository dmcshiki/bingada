/// Browser-only side effects for the audit page (download, open link).
/// The VM/test build gets no-op stubs.
library;

export 'browser_io_stub.dart'
    if (dart.library.js_interop) 'browser_io_web.dart';
