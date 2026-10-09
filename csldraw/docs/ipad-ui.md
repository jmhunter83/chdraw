# iPad UI rework

Krita's interface is built for a desktop with a mouse and keyboard. On an
iPad it is cramped: small targets, many dockers, menus that assume a
keyboard. This is the largest piece of work in the project.

## Goal

Canvas first. She should be able to draw, switch brush, change size and
color, manage layers, undo, and save without a keyboard and without
hunting through menus. Reference points: Clip Studio on iPad and Procreate.

## What we know about her setup

| Item | Value | Effect on the UI |
|---|---|---|
| Hand | Right | Tool sliders and panels on the left edge, out from under the drawing hand |
| iPad | iPad Pro 12.9" (2021, M1) | Large screen; RAM is 8 or 16 GB depending on storage, so test big canvases |
| Pencil | Apple Pencil 2nd gen | Pressure, tilt, double-tap. No hover, no squeeze |
| Upgrade | New iPad and likely Pencil Pro soon | Build hover preview and squeeze as features that turn on when the hardware supports them |

## Procreate as a reference

Procreate is the iPad app people find most fun to draw in. Patterns to borrow:

- Brush, smudge and eraser as three icons top right; everything else one tap away.
- Size and opacity sliders on the screen edge, swappable left or right.
- Hold at the end of a stroke to snap it into a clean line or shape (QuickShape).
- Drag a color onto a closed shape to fill it (ColorDrop).
- Touch and hold for the eyedropper; two-finger tap undo, three-finger tap redo.
- Time-lapse replay of the drawing. Krita's Recorder docker already does this.

## Existing work to build on

| Source | What exists | Status |
|---|---|---|
| Krita upstream, 2026 roadmap | Mobile UI prototype (Timothée); tool option dockers moving to QML so mobile and desktop share them; new text tool already QML | In progress |
| LibrePaint [#64](https://github.com/serika12345/librepaint/issues/64) | Plan: canvas-first variable layout, pen draws / finger navigates, Safe Area, rotation, split view, tap-target and contrast checks | Open, blocked by #61 and #63 |
| Krita 5.x today | Configurable touch gestures (Canvas Input Settings), pop-up palette, canvas-only mode, custom workspaces and toolbars | Shipping |

We build on these instead of starting a third UI. Generic fixes go back to
LibrePaint and, where they apply, to KDE.

## Phases

### A. Configuration only (no code)

Ship a tuned default profile inside the iPad build:

- [ ] Workspace "iPad": canvas-only by default, one slim toolbar, layers and
      brush presets as toggleable panels.
- [ ] Larger icons and slider heights; touch-friendly sliders on.
- [ ] Gestures: two-finger tap = undo, three-finger tap = redo,
      pinch = zoom, two-finger twist = rotate, long press = color picker.
- [ ] Pop-up palette with her ten most-used brushes.
- [ ] Remove menus and dockers she never uses.

### B. Native iPad behavior (small code changes in the fork)

- [ ] Pencil double-tap → configurable action (eraser toggle, pop-up
      palette, undo). Works on her current Pencil 2.
- [ ] After her upgrade: Pencil Pro squeeze → same action menu; hover →
      brush outline preview before contact.
- [ ] Palm rejection: fingers never paint while the Pencil is in use.
- [ ] Safe Area, rotation, Stage Manager, external keyboard shortcuts.

### C. New canvas-first shell (QML)

- [ ] Edge toolbars: brushes left, color and layers right, collapsible.
- [ ] Quick sliders on the canvas edge for size and opacity.
- [ ] Layer panel built for touch: drag to reorder, swipe for options,
      tap thumbnail for visibility.
- [ ] Reuse upstream's QML tool options and LibrePaint #64 layout rules.

## Questions for her

Sent as a page with pictures: https://claude.ai/artifact/3MHKaBM9XaP7HUSDh2ZcCH
(answers come back as text). Hand and Pencil are already known (above).

- [ ] Which tools does she use most in Clip Studio?
- [ ] Simple (Procreate), panels (Clip Studio), or in between?
- [ ] Portrait, landscape, or both?
- [ ] Which finger and Pencil gestures does she rely on?
- [ ] What bugs her in Clip Studio or Krita?
- [ ] One wish for the app.
