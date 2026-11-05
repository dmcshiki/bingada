import 'package:tokingo/core/ui/sound/bingo_sound_stub.dart'
    if (dart.library.js_interop) 'package:tokingo/core/ui/sound/bingo_sound_web.dart'
    as impl;

/// Friendly chime played on every screen when someone calls BINGO.
/// A soft three-note arpeggio: noticeable, never startling. No-op off web and
/// when the browser blocks audio before the first user gesture.
void playBingoChime() => impl.playBingoChime();
