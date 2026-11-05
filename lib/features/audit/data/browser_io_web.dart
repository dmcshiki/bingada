import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves [contents] as a file named [filename] through a Blob + anchor.
bool downloadTextFile(
  String filename,
  String contents, {
  String mime = 'application/json',
}) {
  final blob = web.Blob(
    [contents.toJS].toJS,
    web.BlobPropertyBag(type: '$mime;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(a);
  a
    ..click()
    ..remove();
  web.URL.revokeObjectURL(url);
  return true;
}

/// Opens an absolute http(s) [url] in a new tab, as a real external
/// navigation: a temporary `<a target="_blank" rel="noopener noreferrer">`
/// clicked inside the user's tap. Never touches the app router, so it can't
/// fall into the login redirect. Relative/odd URLs are refused.
bool openExternal(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
    return false;
  }
  final a = web.HTMLAnchorElement()
    ..href = uri.toString()
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..style.display = 'none';
  web.document.body?.append(a);
  a
    ..click()
    ..remove();
  return true;
}
