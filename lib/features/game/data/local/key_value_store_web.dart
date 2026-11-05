import 'dart:async';
import 'dart:js_interop';

import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:web/web.dart' as web;

KeyValueStore createPlatformStore() => WebKeyValueStore();

/// `localStorage` + cross-tab `storage` events.
final class WebKeyValueStore implements KeyValueStore {
  WebKeyValueStore() {
    web.window.addEventListener(
      'storage',
      ((web.StorageEvent e) {
        final key = e.key;
        if (key != null) _ctl.add(key);
      }).toJS,
    );
  }

  final StreamController<String> _ctl = StreamController.broadcast();

  web.Storage get _ls => web.window.localStorage;

  @override
  String? read(String key) => _ls.getItem(key);

  @override
  void write(String key, String? value) {
    if (value == null) {
      _ls.removeItem(key);
    } else {
      _ls.setItem(key, value);
    }
    _ctl.add(key); // `storage` does not fire in the writing tab.
  }

  @override
  Stream<String> get changes => _ctl.stream;
}
