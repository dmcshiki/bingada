Uri appBaseUri() => Uri.parse('https://tokingo.app/');

String appUrl(String path) =>
    appBaseUri().resolve(path.replaceFirst(RegExp('^/+'), '')).toString();

bool openInNewTab(String path) => false;
