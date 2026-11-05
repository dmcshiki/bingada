import 'package:web/web.dart' as web;

String? read(String key) => web.window.sessionStorage.getItem(key);

void write(String key, String? value) {
  if (value == null) {
    web.window.sessionStorage.removeItem(key);
  } else {
    web.window.sessionStorage.setItem(key, value);
  }
}
