import 'dart:async';

import 'package:tokingo/features/game/data/local/key_value_store_stub.dart'
    if (dart.library.js_interop) 'package:tokingo/features/game/data/local/key_value_store_web.dart'
    as platform;

/// Synchronous string key-value store with change notifications.
///
/// On web it is `window.localStorage`, and [changes] also fires for writes
/// made by other tabs (`storage` event). Elsewhere it is in-memory.
abstract interface class KeyValueStore {
  factory KeyValueStore.platform() => platform.createPlatformStore();

  factory KeyValueStore.memory() = MemoryKeyValueStore;

  String? read(String key);

  void write(String key, String? value);

  /// Keys whose value changed (this tab or another).
  Stream<String> get changes;
}

final class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};
  final StreamController<String> _ctl = StreamController.broadcast(sync: true);

  @override
  String? read(String key) => _data[key];

  @override
  void write(String key, String? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _ctl.add(key);
  }

  @override
  Stream<String> get changes => _ctl.stream;
}
