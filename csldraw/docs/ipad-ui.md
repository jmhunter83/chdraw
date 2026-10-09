# iPad UI rework

Krita's interface is built for a desktop with a mouse and keyboard. On an
iPad it is cramped: small targets, many dockers, menus that assume a
keyboard. This is the largest piece of work in the project.

## Goal

Canvas first. She should be able to draw, switch brush, change size and
color, manage layers, undo, and save without a keyboard and without
hunting through menus. Reference points: Clip Studio on iPad and Procreate.

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

- [ ] Pencil double-tap and Pencil Pro squeeze → configurable action
      (eraser toggle, pop-up palette, undo).
- [ ] Pencil hover → brush outline preview before contact.
- [ ] Palm rejection: fingers never paint while the Pencil is in use.
- [ ] Safe Area, rotation, Stage Manager, external keyboard shortcuts.

### C. New canvas-first shell (QML)

- [ ] Edge toolbars: brushes left, color and layers right, collapsible.
- [ ] Quick sliders on the canvas edge for size and opacity.
- [ ] Layer panel built for touch: drag to reorder, swipe for options,
      tap thumbnail for visibility.
- [ ] Reuse upstream's QML tool options and LibrePaint #64 layout rules.

## Questions for her

Answers set the order of phases A–C.

- [ ] Which 10 tools and brushes does she use most in Clip Studio?
- [ ] Which hand does she draw with? Toolbars go on the other side.
- [ ] Portrait, landscape, or both?
- [ ] Which Clip Studio gestures does she rely on?
- [ ] What annoys her most in Krita on the Mac so far?
