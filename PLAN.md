# Wallcards v5 Development Plan

## Project Objectives

1. Port Wallcards from the Noctalia v4 QML plugin system to the Noctalia v5
   Luau plugin API.
2. Preserve the core image-wallpaper browsing experience: discover local
   wallpapers, show thumbnails, navigate quickly, filter the collection, and
   apply a selected wallpaper.
3. Build the plugin from the official v5 example structure and use host-provided
   APIs for panels, widgets, settings, filesystem access, persistent data, and
   wallpaper application.
4. Keep the existing v4 plugin unchanged so it remains available as a behavioral
   and visual reference throughout development.
5. Deliver a reliable image-only first release before attempting advanced visual
   parity with the legacy QML interface.
6. Provide clear errors and useful fallback behavior when the wallpaper
   directory is empty, inaccessible, or contains unsupported files.
7. Keep the implementation maintainable, translatable, and suitable for
   packaging as a Noctalia v5 plugin.

## Scope

### Included

- A Noctalia v5 manifest using `plugin.toml`.
- A bar widget that opens the Wallcards panel.
- An image-wallpaper browser rendered with the v5 declarative `ui.*` API.
- Discovery of wallpapers from Noctalia's configured wallpaper directory.
- Support for common image formats such as PNG, JPEG, and WebP.
- Persistent thumbnail and dominant-colour metadata.
- Previous, next, page, and shuffle navigation.
- Filtering by image properties and dominant-colour group.
- Applying the selected wallpaper through `noctalia.setWallpaper()`.
- Optional live preview while navigating.
- Keyboard controls and IPC entry points.
- Manifest-driven settings.
- English source translations.
- Installation, dependency, usage, IPC, and troubleshooting documentation.

### Excluded from the Initial Release

- Exact pixel-for-pixel reproduction of the v4 QML interface.
- Custom QML windows or components.
- Guaranteed support for the v4 shear transform and full-screen transition
  effects.
- Manual migration of all existing translated locale files.

## Source and Target

The existing implementation remains the reference and must not be modified:

```text
legacy-v4-plugins/wallcards/
```

The v5 implementation will be based on:

```text
official-plugins/example/
```

Target repository structure:

```text
plugin.toml
wallcards.luau
widget.luau
service.luau
thumbnail.webp
README.md
translations/
└── en.json
```

The initial plugin ID is `lgl/wallcards`.

## Architecture

### `plugin.toml`

The manifest will declare:

- Plugin identity and metadata.
- The required v5 plugin API version.
- A bar `widget` entry.
- A `panel` entry for the wallpaper browser.
- A background `service` entry if asynchronous cache maintenance proves useful.
- Panel dimensions, placement, and captured keyboard chords.
- User settings and defaults.

### `widget.luau`

The bar widget will:

- Render the Wallcards glyph.
- Show a translated tooltip.
- Toggle the Wallcards panel when clicked.
- Open plugin settings through the standard host behavior.
- Optionally expose IPC events for opening the panel.

### `wallcards.luau`

The panel will own temporary browsing state:

- Current wallpaper index.
- Active filter and colour group.
- Live-preview state.
- Help visibility.
- Loading and error state.

It will render:

- A header with the current position and primary actions.
- Type or collection filters where useful for an image-only collection.
- Dominant-colour filters.
- A scrollable thumbnail collection.
- A highlighted selected wallpaper.
- Previous, next, shuffle, apply, refresh, settings, and close controls.
- Loading, empty-directory, and command-error messages.

### `service.luau`

If a background service is used, it will:

- Resolve the configured wallpaper directory.
- Scan for supported image files.
- Read cached metadata.
- Generate missing thumbnails and dominant-colour information.
- Publish progress and the completed wallpaper index through
  `noctalia.state`.
- Refresh the index when settings change or when explicitly requested.

The panel may initially perform this work itself if that produces a simpler and
more reliable MVP. Moving cache work into a service should not block the first
working image browser.

### Persistent Data

`noctalia.pluginDataDir()` will contain generated data:

```text
<plugin-data>/
├── wallpapers.json
└── thumbnails/
```

Each wallpaper index record should contain:

```lua
{
  name = "wallpaper.jpg",
  path = "/absolute/path/wallpaper.jpg",
  thumbnail = "/absolute/path/to/cached-thumbnail.jpg",
  dominantColor = "#RRGGBB",
  colorGroup = "Blue",
  size = 0,
  mtime = 0,
}
```

File path, size, and modification time will be used to determine whether a
cached entry is still valid.

## Implementation Plan

### Phase 1: V5 Capability Spike

Create a minimal installable plugin containing one widget and one panel.

Confirm:

- The exact manifest syntax for panel `capture_keys`.
- The appropriate target `plugin_api` version.
- Whether panel dimensions can provide a sufficiently large wallpaper browser.
- How plugin-wide settings are exposed to widget, panel, and service entries.
- The correct local path format for `ui.image`.
- Whether closures work reliably for generated thumbnail callbacks.
- Whether `ui.scroll` performs adequately with at least 200 image entries.
- Whether `noctalia.setWallpaper(path)` applies to all outputs as expected.
- How IPC should address separate widget, panel, and service runtimes.

Exit criteria:

- The plugin installs without manifest errors.
- The widget opens and closes the panel.
- The panel displays one local image.
- Clicking the image applies it as the wallpaper.

### Phase 2: Manifest and Settings

Create the production manifest and initial settings.

Recommended settings:

- `live_preview`
- `default_filter`
- `cards_shown`
- `card_height`
- `card_spacing`
- `center_width_ratio`
- `show_help`
- `show_toolbar`
- `image_extensions`

Settings tied specifically to the legacy QML renderer should be deferred:

- `shear_factor`
- `animation_cards_duration`
- `animation_window_duration`
- `animate_window`
- `card_strip_width`
- `background_color`
- `background_opacity`
- `top_bar_height`

Exit criteria:

- Defaults are seeded correctly.
- Settings are readable from every entry that needs them.
- Settings changes are reflected without corrupting browsing state.

### Phase 3: Image Discovery

Implement wallpaper discovery using:

- `noctalia.wallpaperDirectory()`
- `noctalia.listDir()`
- `noctalia.fileInfo()`
- Configured image-extension matching

The scanner must:

- Ignore directories.
- Match extensions case-insensitively.
- Handle paths containing spaces, quotes, Unicode, and leading dashes.
- Sort results deterministically.
- Return useful states for missing, inaccessible, or empty directories.

Exit criteria:

- PNG, JPG, JPEG, and WebP files are discovered.
- Unsupported files are ignored.
- An empty collection produces a useful panel message.

### Phase 4: Thumbnail and Colour Cache

Generate smaller cached images to avoid repeatedly loading full-resolution
wallpapers into the panel.

Use ImageMagick through `noctalia.runAsync()` to:

- Resize images while preserving aspect ratio.
- Write thumbnails into the plugin data directory.
- Extract a representative dominant colour.
- Map colours to the legacy groups:
  Red, Orange, Green, Teal, Blue, Purple, Pink, and Monochrome.

Requirements:

- Verify `magick` with `noctalia.commandExists()` before starting work.
- Limit concurrent generation jobs.
- Safely quote every external command argument.
- Reuse valid cached thumbnails.
- Update progress through `noctalia.state`.
- Ignore stale index entries for files no longer in the wallpaper directory.
- Defer destructive cache cleanup until cache behavior is well tested.

Exit criteria:

- A second panel open reuses the existing cache.
- Changed images regenerate their metadata.
- Removed images disappear from the browser.
- A missing ImageMagick installation produces a clear error or a direct-image
  fallback.

### Phase 5: Functional Panel

Build a reliable conventional browser before attempting the legacy stacked-card
appearance.

The first panel should provide:

- Scrollable image thumbnails.
- Current selection highlight.
- Current index and total count.
- Previous and next actions.
- Page-back and page-forward actions.
- Shuffle.
- Dominant-colour filtering.
- Apply.
- Optional live preview.
- Refresh.
- Settings.
- Close.
- Loading, empty, and error states.

When filters change:

- Preserve the currently selected image if it remains in the result.
- Otherwise select the first available image.
- Never perform modulo or index operations on an empty list.

Exit criteria:

- All panel actions work with zero, one, and many wallpapers.
- Selection wraps predictably at both ends.
- Filtering never leaves an invalid current index.

### Phase 6: Wallpaper Application

Apply static images through:

```lua
noctalia.setWallpaper(path)
```

Requirements:

- Confirm that the selected file still exists before applying it.
- Report failures through a notification or panel status message.
- Debounce live preview so rapid navigation does not flood the host with
  wallpaper changes.
- Preserve a distinction between selecting an image and explicitly applying it
  when live preview is disabled.
- Define and test behavior across multiple outputs.

Exit criteria:

- Apply works from a thumbnail click, the Apply button, keyboard input, and IPC.
- Live preview remains responsive during rapid navigation.

### Phase 7: Keyboard and IPC Controls

Preserve the useful legacy controls:

| Key | Action |
| --- | --- |
| `J` / `Left` | Previous wallpaper |
| `K` / `Right` | Next wallpaper |
| `H` | Previous page |
| `L` | Next page |
| `R` | Shuffle |
| `Enter` | Apply and close |
| `Space` | Apply |
| `Escape` / `Q` | Close |
| `A` | Clear filters |
| `F` | Toggle the current colour filter |
| `P` | Toggle live preview |
| `?` | Toggle help |

Potential IPC commands:

```sh
noctalia msg panel-toggle lgl/wallcards:wallcards
noctalia msg plugin lgl/wallcards:widget focused open
noctalia msg plugin lgl/wallcards:widget focused previous
noctalia msg plugin lgl/wallcards:widget focused next
noctalia msg plugin lgl/wallcards:widget focused shuffle
noctalia msg plugin lgl/wallcards:widget focused apply
noctalia msg plugin lgl/wallcards:widget focused refresh
```

The final routing will depend on the result of the separate-runtime IPC spike.

Exit criteria:

- Every declared key has one documented action.
- Key press and release events do not trigger actions twice.
- IPC can open the panel and perform the supported headless actions.

### Phase 8: Visual Refinement

After the functional browser is stable, explore a v5 interpretation of the
legacy card deck:

- Larger selected center image.
- Narrower adjacent previews.
- Material-theme colours and spacing.
- Hover states and pointer-friendly controls.
- Smooth selection changes where host APIs permit them.
- Responsive horizontal and vertical layouts.

Do not block the first release on:

- Sheared card transforms.
- Embedded full-screen animations.
- Exact legacy card overlap.
- Frame-by-frame reproduction of QML transitions.

Exit criteria:

- The panel remains usable at supported sizes and UI scales.
- Visual work does not regress scrolling or image-loading performance.

### Phase 9: Translation and Documentation

Port English strings from:

```text
legacy-v4-plugins/wallcards/i18n/en.json
```

to:

```text
wallcards-v5/translations/en.json
```

Use `noctalia.tr()` for visible source strings. Other locale files should be
handled through the normal Noctalia translation process rather than copied
without review.

The README must document:

- Installation.
- Supported image formats.
- ImageMagick dependency and fallback behavior.
- Configuration.
- Keyboard controls.
- IPC.
- Persistent cache location.
- Multi-monitor behavior.
- Differences from the v4 plugin.
- Known limitations.

## Validation Matrix

Test at least the following:

- Missing wallpaper directory.
- Empty wallpaper directory.
- One wallpaper.
- More than 200 wallpapers.
- Mixed PNG, JPEG, and WebP files.
- Unsupported and corrupt files.
- Filenames containing spaces, quotes, Unicode, and leading dashes.
- Missing ImageMagick.
- Thumbnail command failure.
- Cache reuse after plugin or shell restart.
- Adding, changing, and removing wallpapers.
- Filters producing zero results.
- Navigation wrapping in both directions.
- Rapid navigation with live preview enabled.
- Multiple monitors.
- Different panel sizes and UI scale factors.
- Widget and IPC panel opening.
- Plugin reload while thumbnail jobs are active.

Run Luau LSP diagnostics and manifest validation before runtime acceptance
testing.

## Delivery Milestones

1. **Skeleton:** The plugin installs and its widget opens an empty panel.
2. **Image MVP:** Images are discovered, displayed, navigated, and applied.
3. **Cache:** Persistent thumbnails, dominant colours, progress, and refresh are
   working.
4. **Interaction parity:** Filters, keyboard controls, live preview, IPC, and
   settings are working.
5. **Polish:** Center-card styling, responsive layout, documentation,
   translations, and performance improvements are complete.

## Definition of Done

The initial Wallcards v5 release is complete when:

- It installs and enables as a valid Noctalia v5 plugin.
- Its bar widget reliably opens the wallpaper panel.
- It discovers supported images from the configured wallpaper directory.
- It presents a responsive, navigable thumbnail browser.
- It applies the selected image correctly.
- Filters, shuffle, keyboard controls, live preview, settings, and documented
  IPC commands work.
- Thumbnail caching is persistent and resilient to changed or removed files.
- Empty directories, missing dependencies, and failed image processing are
  handled without crashing the plugin.
- English source strings are translatable.
- The README accurately describes installation, behavior, and limitations.
- The legacy v4 plugin remains untouched.
