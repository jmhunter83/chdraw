# chdraw

Jacob's fork of [LibrePaint](https://github.com/serika12345/librepaint) (a
Krita derivative) for one artist across an iPad, a MacBook, and a Windows
laptop with a Wacom tablet. Built on Krita, saved in open formats, synced
through ordinary cloud folders. Personal use only.

| Device | App | Status |
|---|---|---|
| MacBook | Krita 5.3 (Homebrew or krita.org) | Working |
| Windows laptop + Wacom | Krita 5.3 (krita.org or `winget install KDE.Krita`) | To install |
| iPad + Apple Pencil | Krita built from this repo | Not built yet |

Drawings are `.kra` files in iCloud Drive or Google Drive. Export PSD or PNG
to share outside Krita.

## Layout

Everything specific to this fork lives in `chdraw/`. The rest of the repo is
LibrePaint, kept as close to upstream as possible so its updates merge cleanly.

| Path | Purpose |
|---|---|
| [docs/decisions.md](docs/decisions.md) | Why Krita and LibrePaint; risks |
| [docs/ipad-build.md](docs/ipad-build.md) | Build, sign, and install the iPad app |
| [docs/ipad-ui.md](docs/ipad-ui.md) | Plan for a touch-first iPad interface |
| [docs/clip-import.md](docs/clip-import.md) | Bring Clip Studio `.clip` files into Krita |
| [scripts/clip2kra.sh](scripts/clip2kra.sh) | Batch-convert `.clip` → `.kra` |
| [scripts/sign-ipa.sh](scripts/sign-ipa.sh) | Sign the iPad build with an Apple Developer account |
| [docs/archive/](docs/archive/) | Superseded plans |


## Next steps

- [x] Fork LibrePaint to `jmhunter83/chdraw`.
- [ ] Install Krita on the Windows laptop; set up the Wacom.
- [ ] Convert a few Clip Studio files with `chdraw/scripts/clip2kra.sh` and compare.
- [ ] Get her answers to the iPad UI questions ([docs/ipad-ui.md](docs/ipad-ui.md)).
- [ ] Build and install the iPad app ([docs/ipad-build.md](docs/ipad-build.md)).

## Licenses

LibrePaint and Krita: GPL-3.0.
clip_to_psd (downloaded by `clip2kra.sh`): MIT.
