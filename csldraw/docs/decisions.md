# Decisions

## 2026-10-09: Krita everywhere, LibrePaint fork for the iPad

**Decision.** Stock Krita 5.3 on the Mac and the Windows laptop. On the iPad, a
Krita build from our fork of LibrePaint, [jmhunter83/csldraw](https://github.com/jmhunter83/csldraw). Drawings are `.kra` files synced
through iCloud Drive or Google Drive.

**Why Krita.** Krita already matches or beats Clip Studio for painting, line
art, and animation, saves to an open zip-based format, and runs on Mac and
Windows with full Wacom support. Jacob installed Krita 5.3.4.1 and confirmed
it works. Writing a new engine (the first plan, archived in
[archive/2026-10-rust-engine-plan.md](archive/2026-10-rust-engine-plan.md))
would take years to reach the same point.

**Why LibrePaint.** Krita has no official iPad version. LibrePaint, a GPL-3.0
Krita derivative, already runs on a physical iPad: Qt 6.11.1, KF6, OpenGL ES
3.0 canvas, Apple Pencil pressure and tilt, Files open/save, KRA/ORA round
trip (its issue #67, August 2026).

**Why fork LibrePaint directly** instead of extracting its iOS patches onto
upstream Krita: faster start, and its Nix/Xcode build is already
reproducible. Accepted cost: we depend on a one-person project and inherit
its renames.

**Why GPL is not a problem.** The app is installed on her own iPad with
Jacob's developer account. It is not distributed through the App Store.

## Risks

| Risk | Effect | Mitigation |
|---|---|---|
| LibrePaint is maintained by one person | Fork may go stale | We own our fork; can rebase onto upstream Krita later |
| LibrePaint tracks Krita master (6.1-prealpha); desktop runs 5.3 | `.kra` features from 6.1 may not open in 5.3 | Test round trips; move desktop to Krita 6.x if needed |
| Apple deprecated OpenGL ES; Krita's canvas uses it | A future iPadOS could break the canvas | LibrePaint #63 plans a Vulkan backend |
| iPad memory limits | Large canvases may be killed by iPadOS | LibrePaint caps tile memory; test her largest files |
| Builds need a Mac with a pinned Xcode | Cloud sessions cannot build the iPad app | Build on Jacob's Mac |
| Krita's desktop UI on a tablet | Hard to use with fingers | [ipad-ui.md](ipad-ui.md) |

## Clip Studio import

See [clip-import.md](clip-import.md). The batch converter
(`csldraw/scripts/clip2kra.sh`) uses clip_to_psd (MIT) and Krita's command-line
export. A native `.clip` importer on clipparse (MIT) is planned for later.
