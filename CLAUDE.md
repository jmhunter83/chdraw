# CLAUDE.md

This repo is `jmhunter83/chdraw`, Jacob's fork of LibrePaint (a Krita
derivative) for his daughter's iPad, Mac and Windows drawing setup.

- Communicate in English. `AGENTS.md` is LibrePaint's upstream contract: follow
  its engineering rules (build, test, verification), but not its rule to report
  in Japanese.
- Fork-specific docs and scripts live in `chdraw/`. Start with
  `chdraw/README.md` and `chdraw/docs/decisions.md`.
- Keep changes outside `chdraw/` small and isolated so upstream LibrePaint
  updates merge cleanly.
- iPad and macOS builds need Jacob's Mac (pinned Xcode + Nix); cloud sessions
  are Linux and cannot build or sign them.
