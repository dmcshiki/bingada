final Map<String, String> _mem = {};

String? read(String key) => _mem[key];

void write(String key, String? value) {
  if (value == null) {
    _mem.remove(key);
  } else {
    _mem[key] = value;
  }
}
