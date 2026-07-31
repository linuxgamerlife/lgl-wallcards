# Wallcards

Wallcards is an image-only wallpaper browser for Noctalia v5. It discovers
images in Noctalia's configured wallpaper directory and presents them in a
large card grid.

## V5 Port Limitations

This project is a functional adaptation of Wallcards for Noctalia v5, not a
faithful reproduction of the original v4 interface. It has reached the
practical limit of the current public v5 plugin API.

Noctalia v5 plugins render host-owned, flex-based `ui.*` controls. The API does
not currently expose the capabilities used by the original QML implementation:

- custom full-screen plugin windows
- absolute and overlapping card positioning
- matrix and shear transforms
- per-card movement and resizing animations
- shader masks and other QML graphical effects
- custom window entrance and exit animations
- mouse-wheel callbacks inside a plugin panel
- equivalent control over keyboard focus and panel input

As a result, this version must behave and look like a standard Noctalia panel.
Its colours, spacing, controls, and static card hierarchy can be refined, but
the original stacked, sheared, animated, wheel-controlled experience cannot be
recreated with the current API.

A faithful port will require additional Noctalia v5 APIs for absolute layout,
transforms, animation, and panel pointer-wheel events. Until then, the original
v4 plugin remains the complete visual implementation and this project provides
the simplified v5 alternative.

## Status

This is an early v5 implementation. It currently supports:

- PNG, JPEG, and WebP wallpapers
- name and modification-time sorting
- configurable wallpaper directory and image extensions
- previous, next, and shuffle navigation
- selection highlighting
- applying a wallpaper to all outputs
- optional live preview
- a persistent JSON wallpaper index
- refresh through the panel, widget IPC, or service IPC

Thumbnail generation, dominant-colour filtering, keyboard capture, and animated
card transitions remain planned work.

## Plugin

| Field | Value |
| --- | --- |
| ID | `lgl/wallcards` |
| Entries | Widget: `wallcards`; panel: `browser`; service: `scanner` |
| Required plugin API | 15 |

## Installation

Clone the repository:

```sh
git clone git@github.com:linuxgamerlife/lgl-wallcards.git
cd lgl-wallcards
```

Lint the plugin before loading it:

```sh
noctalia plugins lint .
```

Expose the working copy through Noctalia's local development plugin directory:

```sh
mkdir -p ~/.local/share/noctalia/plugins
ln -s "$(pwd)" ~/.local/share/noctalia/plugins/lgl-wallcards
```

If the link already exists, verify where it points:

```sh
readlink ~/.local/share/noctalia/plugins/lgl-wallcards
```

With Noctalia running, confirm that it discovered the plugin and enable it:

```sh
noctalia msg plugins list
noctalia msg plugins enable lgl/wallcards
```

Open the browser directly for the first test:

```sh
noctalia msg panel-toggle lgl/wallcards:browser
```

Then open **Settings → Plugins**, confirm that Wallcards is enabled, and add
the `wallcards` widget through the bar's Add Widget interface.

### Reloading During Development

Changes made in the cloned repository are visible through the local symlink.
If Noctalia does not reload a change automatically, disable and re-enable the
plugin:

```sh
noctalia msg plugins disable lgl/wallcards
noctalia msg plugins enable lgl/wallcards
```

### Compatibility

Wallcards currently requires plugin API 15. If it appears as incompatible,
check the installed Noctalia version and update Noctalia before testing:

```sh
noctalia --version
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

## Credits

- The original Noctalia v4 Wallcards plugin was created by
  [tonigineer](https://github.com/tonigineer).
- The original design was inspired by
  [ilyamiro's NixOS configuration](https://github.com/ilyamiro/nixos-configuration)
  and [liixini's skwd](https://github.com/liixini/skwd).
- The v5 implementation is built against the
  [official Noctalia plugin examples](https://github.com/noctalia-dev/official-plugins).
