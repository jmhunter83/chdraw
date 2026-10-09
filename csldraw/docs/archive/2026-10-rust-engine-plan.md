> **Archived 2026-10-09.** Superseded by the Krita-based plan in
> [`docs/decisions.md`](../decisions.md). Kept for reference; not being built.

# chdraw — open-format drawing app for iPad, Mac and Windows

## Context

Jacob's daughter draws in Clip Studio Paint on an iPad, a MacBook and a Windows
gaming laptop with a Wacom tablet. Clip Studio stores work in a proprietary
`.clip` format and its own cloud, which syncs poorly through iCloud Drive and
Google Drive. Goal: a personal-use drawing app, Rust core with thin native
shells, that saves to open formats as single files so any file-sync service
works. Personal use only, so licensing of reference code is not a constraint.

Decisions already made (from the user):
- Scope: illustration/painting, comics/manga, sketching/line art. Animation later.
- Sequencing: build all three platforms together.
- Apple Developer Program: Jacob already has an account → install on iPad via
  TestFlight/ad hoc.

The repo (`jmhunter83/chdraw`, branch `claude/serene-volta-xwtcc5`) is empty.

## Architecture

```
chdraw/
  crates/
    chdraw-core/     document model, tiled raster, brush engine, undo, selection, fill
    chdraw-render/   wgpu compositor (Metal on Apple, DX12/Vulkan on Windows)
    chdraw-formats/  OpenRaster read/write (native), PSD export/import, PNG/JPEG
    chdraw-ffi/      UniFFI bindings → Swift XCFramework for the iPad app
  apps/
    desktop/         Rust: winit + egui shell. Same UI on Mac and Windows.
    ipad/            Swift/SwiftUI shell, document-based app, hosts a CAMetalLayer
  docs/              format spec for chdraw extensions inside .ora
```

Why this split:
- One Rust engine = identical brush feel and file output on every device.
- egui desktop shell covers Mac and Windows with one UI codebase. PhotoCraft
  (storytold, MIT/Apache, egui + wgpu, pressure/tilt brushes) proves the stack.
- iPad needs Swift: Apple Pencil data (coalesced + predicted touches, tilt,
  azimuth, hover, squeeze/barrel roll) and Files-app document integration are
  UIKit APIs. egui on iOS does not handle these well.

## Key components

**Input abstraction** (`chdraw-core::input`): one `StylusSample { pos, pressure,
tilt, azimuth, twist, timestamp, predicted }` type. Each shell converts its
native events into it.
- iPad: `UITouch` coalesced + predicted touches, `UIPencilInteraction`.
- Windows: Windows Ink via `octotablet` crate (Ink backend complete per README)
  or direct `WM_POINTER` via the `windows` crate. Wintab not needed at first.
- Mac: verify how PhotoCraft gets pressure (NSEvent tablet events); copy it.

**Canvas engine** (`chdraw-core`):
- Sparse 256×256 RGBA tiles, 16-bit per channel internally for smooth blending.
- Layers, groups, opacity, blend modes, clipping masks, layer masks, lock alpha.
- Dab-based brush engine: pressure/tilt curves for size, opacity, flow; spacing;
  stabilizer (lazy-nezumi style + moving average). Brush presets as JSON.
- Undo: tile-level copy-on-write snapshots.
- Tools by milestone (below).

**Files and sync** (`chdraw-formats`):
- Native format: OpenRaster `.ora` (zip: `stack.xml` + PNG per layer +
  `mergedimage.png` + thumbnail). Opens in Krita, GIMP and MyPaint.
- chdraw-only data (brush used, panel borders, tone settings) goes in a
  namespaced XML attribute set and extra files inside the zip. Other apps
  ignore it; the image still opens.
- Single file per drawing → iCloud Drive, Google Drive and OneDrive sync it
  atomically. Avoid package directories (Google Drive handles them badly).
- Save atomically (write temp, rename). iPad uses `UIDocument` +
  `NSFileCoordinator`, so the Files app, iCloud Drive and the Google Drive file
  provider all work without custom sync code.
- Export: layered PSD (Procreate and Clip Studio both import it), PNG, JPEG.
- No custom cloud service.

## Milestones (all three platforms advance together)

- [ ] **M0 Skeleton**: Cargo workspace, Xcode project, CI that builds desktop
  (macOS + Windows) and the iPad XCFramework. Blank canvas renders on all three.
- [ ] **M1 First real drawing**: pressure brush, eraser, color picker, undo/redo,
  pan/zoom/rotate, save/open `.ora`. Verify a file round-trips iPad → Mac →
  Windows → Krita.
- [ ] **M2 Layers**: layer panel, blend modes, opacity, clipping, groups,
  stabilizer, brush preset editor, iPad gestures (two-finger tap undo).
- [ ] **M3 Line art and fill**: lasso fill, bucket fill with gap closing and
  reference-layer sampling, selection tools, transform/warp.
- [ ] **M4 Comics**: panel border tool, screentone layers, text layers, rulers
  (straight, perspective, symmetry).
- [ ] **M5 Interop**: PSD import/export, import of existing `.clip` files for
  migrating old work (via an open-source `.clip` reader, to be evaluated).
- [ ] **Later — Animation**: frames, onion skin, timeline, export GIF/MP4.

## Reference code to mine

| Project | Use for | License |
|---|---|---|
| PhotoCraft (storytold, Rust, egui + wgpu) | egui shell, wgpu compositor, pen input, PSD I/O | MIT/Apache |
| Krita (C++/Qt) | brush engine design, ORA writer, fill gap closing, tablet handling | GPL |
| MyPaint / libmypaint (C) | brush dynamics model, ORA reference | ISC/GPL |
| Graphite (Rust) | node/layer architecture, wgpu usage | Apache |

## Verification

- `cargo test` in `chdraw-core` and `chdraw-formats`: ORA write → read round
  trip is byte-for-byte equal in pixels; blend mode results match reference
  images.
- Interop check: open chdraw `.ora` in Krita
  (`krita in.ora --export --export-filename out.png`), compare against
  chdraw's `mergedimage.png`.
- Pen check per platform: built-in pressure test screen plots pressure and tilt
  for iPad Pencil, Wacom on Windows, and Mac (Sidecar).
- Sync check: save on iPad to iCloud Drive and Google Drive, open on Mac and
  Windows, edit, reopen on iPad.
- iPad on-device testing through TestFlight.

## First implementation step after approval

M0 only: workspace skeleton, egui desktop shell with wgpu canvas, iPad Xcode
project with UniFFI bridge, CI. Commit and push to `claude/serene-volta-xwtcc5`.
Note: the iPad and macOS builds need Xcode on a Mac; this cloud container is
Linux, so Apple builds run in GitHub Actions macOS runners or on Jacob's Mac.
