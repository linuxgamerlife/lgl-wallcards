# Wallcards

Wallcards is an image-only wallpaper browser for Noctalia v5. It discovers
images in Noctalia's configured wallpaper directory and presents them in a
large card grid.

## Status

This is an early v5 implementation. It currently supports:

- PNG, JPEG, and WebP wallpapers
- name and modification-time sorting
- configurable grid columns and image extensions
- previous, next, and shuffle navigation
- selection highlighting
- applying a wallpaper to all outputs
- optional live preview
- a persistent JSON wallpaper index
- refresh through the panel, widget IPC, or service IPC

Thumbnail generation, dominant-colour filtering, keyboard capture, and the
legacy stacked-card visual treatment remain planned work.

## Plugin

| Field | Value |
| --- | --- |
| ID | `lgl/wallcards` |
| Entries | Widget: `wallcards`; panel: `browser`; service: `scanner` |
| Required plugin API | 15 |

## Installation

Place this directory in a configured Noctalia v5 plugin source, enable
Wallcards in Settings, then add the `wallcards` widget to the bar.

The panel can also be opened directly:

```sh
noctalia msg panel-toggle lgl/wallcards:browser
```

## IPC

The widget accepts:

```sh
noctalia msg plugin lgl/wallcards:wallcards focused open
noctalia msg plugin lgl/wallcards:wallcards focused refresh
```

The scanner service accepts a `refresh` event when addressed through Noctalia's
plugin IPC routing.

## Persistent Data

The scanner writes `wallpapers.json` under the directory returned by
`noctalia.pluginDataDir()`. The file is an index and may be regenerated from
the configured wallpaper directory.

## Development References

- `PLAN.md` contains the phased v5 development plan.
- `legacy-v4-plugins/wallcards/` is the behavior and design reference.
- `official-plugins/example/` is the v5 API template.
