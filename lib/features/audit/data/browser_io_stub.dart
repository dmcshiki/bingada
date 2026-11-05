/// Saves [contents] as a file named [filename]. No-op outside the web.
bool downloadTextFile(
  String filename,
  String contents, {
  String mime = 'application/json',
}) => false;

/// Opens [url] in a new tab. No-op outside the web.
bool openExternal(String url) => false;
