# Calculator · public specification

This folder describes how the calculator of the reference system (macOS 27) looks and
behaves, as observed by measurement. Silica follows a clean-room process: the observations
were made on a real machine and are restated here in our own words, with the numbers that
came out of them. The raw material (screenshots, screen recordings, accessibility dumps,
session notes) stays in the private repository `silica-reference` and is not reproduced here.

## Conventions

- **IDs.** `CA-01` and `CA-02` name the two measurement sessions of this app. A value in
  these files comes from one of them; the tables say which when it matters.
- **Units.** Lengths are points at 1× (1 pt = 1 px on the reference display). Positions are
  measured from the top-left corner of the window unless a table says otherwise.
- **Colours.** sRGB hex. Neutral grays were read directly; saturated colours were converted
  from the display profile to sRGB, and only the sRGB value is given.
- **Timing.** Recorded at 75 Hz: one frame is 13.3 ms, which is also the precision of every
  time given here. Times are counted from the input event named in each table.
- **Status.** Values marked *provisional* are estimates or single readings that need a
  second look; items marked *unmeasured* were not observed at all.
- **Labels.** English, matching `lib/l10n/app_en.arb` where the app already has a string.
  They name controls; they are not quotations of the reference interface.

## Reference conditions

Display 2560 × 1440 at 1×, 75 Hz, solid mid-gray wallpaper. The app was tested in both
system appearances; it renders identically in both (see [window.md](window.md)).

## Files

| File | Covers |
| --- | --- |
| [window.md](window.md) | Appearance, window sizes per mode, toolbar, inactive window, first-run tip |
| [keys.md](keys.md) | Key roles and fills, glyph sizes, hover / pressed / keyboard states, timing |
| [display.md](display.md) | Entry and result lines, long numbers, convert, RPN stack, programmer panel |
| [history.md](history.md) | History sidebar |
| [modes-and-menus.md](modes-and-menus.md) | Mode switching, mode menu, menu bar structure |
| [diagrams/basic-layout.svg](diagrams/basic-layout.svg) | Basic mode geometry |
| [diagrams/press-timing.svg](diagrams/press-timing.svg) | Key press and release timeline |
