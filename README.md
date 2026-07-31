# Wallcards

Wallcards is an image-only wallpaper browser for Noctalia v5. It discovers
images in Noctalia's configured wallpaper directory and presents them in a
large card grid.

## V5 Port Limitations

This project is a functional adaptation of Wallcards for Noctalia v5, not a
faithful reproduction of the original v4 interface. Based on the currently
available public documentation, API definitions, and official examples, the v5
plugin API does not appear to provide everything required to reproduce that
interface faithfully. This assessment may change as the API evolves or as
additional implementation techniques become documented.

Noctalia v5 plugins render host-owned, flex-based `ui.*` controls. The API does
not currently appear to expose direct equivalents for several capabilities
used by the original QML implementation:

- custom full-screen plugin windows
- absolute and overlapping card positioning
- matrix and shear transforms
- per-card movement and resizing animations
- shader masks and other QML graphical effects
- custom window entrance and exit animations
- mouse-wheel callbacks inside a plugin panel
- equivalent control over keyboard focus and panel input

As a result, this version currently behaves and looks like a standard Noctalia
panel. Its colours, spacing, controls, and static card hierarchy can be refined,
but the original stacked, sheared, animated, wheel-controlled experience has
not been reproducible using the documented API surface available during
development.

A faithful port may require additional Noctalia v5 APIs for absolute layout,
transforms, animation, and panel pointer-wheel events, or an approach not
covered by the currently available documentation and examples. The original v4
plugin remains the complete visual implementation while this project provides
a simplified v5 alternative.

## AI-Assisted Development Notice

This port was created primarily with the assistance of a large language model
(LLM), using the legacy Wallcards source, the public Noctalia v5 documentation,
local API definitions, and official plugin examples as references.

LLM-generated code can contain incorrect assumptions, subtle defects, insecure
patterns, or behavior that differs from its description. Although the project
has passed Noctalia's offline plugin lint, that does not replace human review or
runtime testing. Users and contributors should:

- review changes before running or distributing them
- test the plugin in a non-critical environment first
- verify filesystem paths, external commands, and configuration values
- avoid relying on the plugin for backups or preservation of important data
- report unexpected behavior and validate fixes independently

This software is provided without warranty, subject to the terms of its
license. Neither the authors nor the tools used to assist development guarantee
fitness, correctness, security, or compatibility with future Noctalia releases.

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
git clone https://github.com/linuxgamerlife/lgl-wallcards.git
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

## Removal

Disable Wallcards before removing its local development link:

```sh
noctalia msg plugins disable lgl/wallcards
unlink ~/.local/share/noctalia/plugins/lgl-wallcards
```

This removes Wallcards from Noctalia without deleting the cloned repository.
Delete the clone separately if it is no longer needed.

Wallcards may leave its generated `wallpapers.json` index in Noctalia's plugin
data directory. No wallpaper images are stored or deleted by the removal
commands above.

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
