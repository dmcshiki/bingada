import 'package:web/web.dart' as web;

bool openInNewTab(String path) {
  final url = Uri.base.resolve(path).toString();
  web.window.open(url, '_blank');
  return true;
}
