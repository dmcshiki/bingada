import 'package:web/web.dart' as web;

web.AudioContext? _ctx;

void playBingoChime() {
  try {
    final ctx = _ctx ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
    final now = ctx.currentTime;
    // E5, G5, C6: a bright major arpeggio with a soft attack.
    const notes = [659.25, 783.99, 1046.5];
    for (var i = 0; i < notes.length; i++) {
      final start = now + i * 0.13;
      final osc = ctx.createOscillator()
        ..type = 'triangle'
        ..frequency.value = notes[i];
      final gain = ctx.createGain();
      gain.gain
        ..setValueAtTime(0, start)
        ..linearRampToValueAtTime(0.22, start + 0.02)
        ..exponentialRampToValueAtTime(0.001, start + 0.55);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc
        ..start(start)
        ..stop(start + 0.6);
    }
  } on Object {
    // Audio is a nicety; never break the game for it.
  }
}
