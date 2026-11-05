import 'package:web/web.dart' as web;

/// The app root (`<base href>`), e.g. `https://host/bingada/`.
Uri appBaseUri() => Uri.parse(web.document.baseURI);

/// Resolves an app route (e.g. `/s/2TSX`) against the `<base href>`.
String appUrl(String path) =>
    appBaseUri().resolve(path.replaceFirst(RegExp('^/+'), '')).toString();

bool openInNewTab(String path) {
  web.window.open(appUrl(path), '_blank');
  return true;
}
