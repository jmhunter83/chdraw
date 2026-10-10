# Importing Clip Studio art

Clip Studio saves drawings as `.clip`, a proprietary format. Krita cannot open
`.clip` directly. Use one of the routes below to bring drawings over as `.kra`.

## Which route to use

| Route | Needs | Best for |
|---|---|---|
| 1. Export from Clip Studio | Clip Studio installed | A few drawings, or files with vector/tone layers |
| 2. `chdraw/scripts/clip2kra.sh` | Python 3, Krita | Whole folders, without opening Clip Studio |
| 3. Native `.clip` import (planned) | iPad build | Opening `.clip` straight from Files on the iPad |

## Route 1: export from Clip Studio

1. Open the drawing in Clip Studio.
2. Rasterize vector, tone and frame-border layers you want to keep
   (Layer → Rasterize). PSD has no equivalent for them.
3. File → Export (Single Layer) or Save as → `.psd`.
4. Open the `.psd` in Krita and save as `.kra`.

## Route 2: batch converter

`chdraw/scripts/clip2kra.sh` converts `.clip` → `.psd` → `.kra` without Clip Studio.
It uses [clip_to_psd](https://github.com/dobrokot/clip_to_psd) (MIT), pinned to
commit `e8db68c` and checked by SHA-256, then Krita's command-line export.

Copy the `.clip` files off the iPad first: in Clip Studio on iPad, export or
share them to Files (iCloud Drive), or pull them from Clip Studio's cloud on
the Mac.

```sh
# Mac, with Krita installed via Homebrew or krita.org
chdraw/scripts/clip2kra.sh ~/Desktop/clip-files ~/Desktop/krita-files

# keep the intermediate PSDs too
chdraw/scripts/clip2kra.sh --keep-psd ~/Desktop/clip-files ~/Desktop/krita-files

# PSD only, no Krita needed
chdraw/scripts/clip2kra.sh --psd-only ~/Desktop/clip-files ~/Desktop/psd-files
```

- Subfolders are mirrored in the output folder.
- Results and warnings go to `clip2kra.log` in the output folder.
- Krita opens briefly for each file; this is normal.
- Set `KRITA=/path/to/krita` if Krita is not in `/Applications`.
- Optional: `pip3 install Pillow` adds PSD thumbnails.

### What survives

Tested 2026-10-09 with clip_to_psd's feature test file and Krita 5.3.4.1:

| Kept | Lost |
|---|---|
| Folders and nesting | Filter layers (Levels, HSL, Curves): clip_to_psd writes them, Krita's PSD import drops them |
| Pixel layers, opacity, blend modes | Vector layers (rasterized only if Clip Studio stored pixels) |
| Layer masks | Tone (screentone) layers |
| Text, as editable Krita text | Frame borders |
| Solid color and gradient fill layers | 3D models, rulers, animation timelines |
| Layer names, visibility | Color Balance, Posterize, Binarize, Gradient Map |

Always open a converted file and compare it against the original before
deleting anything.

## Route 3: native import (planned)

A Krita import filter built on [clipparse](https://github.com/wamsoft/clipparse)
(MIT, C++17). It would map Clip Studio masks to Krita transparency masks and
clipping to Krita alpha inheritance, and let the iPad open `.clip` from Files.
Not started.
