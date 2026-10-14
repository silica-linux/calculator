# AGENTS.md

Calculator is a Silica app: the rules of `silica-desktop/AGENTS.md` apply (clean-room, assets,
never crash, everything is a command, measured parity, English everywhere). On top of them:

## Clean-room

- Observations of the reference system live in the private repository `silica-reference`
  (`calculator.md`, request CA-01), never here. Here only the request codes and the measured
  numbers are cited.
- Interface texts are our own words, in English with translations (`lib/l10n/*.arb`).
  No Apple product names, no texts copied from the reference interface.

## Work

- Plan and bugs: the issues of this repository and the Silica board
  (https://github.com/orgs/silica-linux/projects/1).
- Before every commit: `dart format --set-exit-if-changed lib test`,
  `flutter analyze --fatal-infos`, `flutter test`, `tool/check_assets.sh`. One task per commit.
- Visual work: screenshots inside Ossido (`silica-cli … screenshot`), compared with the
  reference shots; `docs/parity.md` gets only measured numbers.
- Every user action is a `calculator.*` command, listed in `docs/spec.md`.
- `silica_ui` comes from a tag (`ref` in `pubspec.yaml`); widgets other apps need go into
  `silica-ui`.
- Never crash: a division by zero, a root of a negative, a pasted string are normal cases
  (the display shows Error, nothing throws past the engine).
