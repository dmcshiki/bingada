/// Build-time configuration.
library;

/// Runs fully offline with local repositories (no Firebase config needed).
/// Build with `--dart-define=TOKINGO_DEMO=false` for the real backend.
const bool kDemoMode = bool.fromEnvironment('TOKINGO_DEMO', defaultValue: true);

/// Use the local Firebase emulators (`firebase emulators:start`).
const bool kUseEmulators = bool.fromEnvironment('TOKINGO_EMULATORS');

/// Commit the build was made from (CI passes `--dart-define=GIT_SHA=...`).
const String kGitSha = String.fromEnvironment('GIT_SHA', defaultValue: 'dev');

/// Public repository root, linked from the audit page. Always the root: the
/// `/commit/<sha>` page of a big commit times out on GitHub (504).
const String kRepoUrl = String.fromEnvironment(
  'TOKINGO_REPO_URL',
  defaultValue: 'https://github.com/dmcshiki/bingada',
);
