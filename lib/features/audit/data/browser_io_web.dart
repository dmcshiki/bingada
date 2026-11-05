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

/// Opens [url] in a new tab (no opener).
bool openExternal(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
  return true;
}
