# Building Krita for the iPad

The iPad build comes from this repo, `jmhunter83/csldraw`, a fork of
[LibrePaint](https://github.com/serika12345/librepaint), a GPL-3.0 Krita
derivative with a working iPadOS port. LibrePaint signs through AltStore;
we sign with Jacob's Apple Developer account instead (`csldraw/scripts/sign-ipa.sh`).
Run all commands from the repo root.

Status: **not built yet.** Steps below are from LibrePaint's
`docs/architecture/DEVELOPMENT.md` (Japanese), checked against its source on
2026-10-09. `csldraw/scripts/sign-ipa.sh` has not been run yet; first run is on Jacob's Mac.

## What LibrePaint pins

From `packaging/ios/versions.env` at LibrePaint commit `e9946cc` (2026-10-03):

| Item | Version |
|---|---|
| Krita base | master @ `71738259` (6.1.0-prealpha) |
| Qt | 6.11.1 |
| KDE Frameworks | 6.28.0 |
| Xcode | 26.6 (17F113), iOS SDK 26.5 |
| Deployment target | iOS/iPadOS 17.0, arm64 |
| Nix | 2.31 or later |

LibrePaint's build refuses other Xcode versions unless overridden.

## 1. Clone

- [x] Fork LibrePaint to `jmhunter83/csldraw` (done; `master` = LibrePaint `e9946cc`).
- [ ] Clone on the Mac: `git clone https://github.com/jmhunter83/csldraw`

The fork copied only `master`. LibrePaint's newer work is on its `develop`
branch. To pull it in later:

```sh
git remote add upstream https://github.com/serika12345/librepaint
git fetch upstream develop
```

## 2. Prepare the Mac (Apple Silicon)

- [ ] Install Xcode 26.6 at `/Applications/Xcode.app` (older versions:
      developer.apple.com/download/all).
- [ ] Install Nix 2.31+ with flakes enabled, and direnv.
- [ ] Let the Nix sandbox see Xcode. In the Nix daemon config (nix-darwin shown):

  ```nix
  nix.settings.sandbox = true;
  nix.settings.sandbox-fallback = false;
  nix.settings.extra-allowed-impure-host-deps = [ "/Applications/Xcode.app" ];
  ```

- [ ] Check the host:

  ```sh
  cd csldraw
  nix develop .#librepaint-ios
  packaging/ios/scripts/check-host.sh
  ```

## 3. Build the unsigned IPA

```sh
nix build .#librepaint-ios-ipa --out-link build-ios/nix-results/librepaint-ios-ipa
```

Output: `build-ios/nix-results/librepaint-ios-ipa/LibrePaint-iOS-unsigned.ipa`
(about 87 MiB). The first build compiles Qt, KDE Frameworks and ~58
dependencies; expect hours.

## 4. Set up signing (once)

- [ ] On the iPad: Settings → Privacy & Security → Developer Mode → on.
- [ ] Connect the iPad by USB, unlock it, trust the Mac.
- [ ] Get its device ID: `xcrun devicectl list devices`
- [ ] developer.apple.com → Certificates, IDs & Profiles:
  - Register the iPad (Devices → +, UDID from Finder or devicectl).
  - Create an explicit App ID, e.g. `com.jmhunter83.krita`.
  - Create an **iOS App Development** profile for that App ID, including
    the iPad and your Apple Development certificate. Download it.
- [ ] Find the signing identity: `security find-identity -v -p codesigning`

## 5. Sign and install

```sh
csldraw/scripts/sign-ipa.sh \
  --ipa build-ios/nix-results/librepaint-ios-ipa/LibrePaint-iOS-unsigned.ipa \
  --profile ~/Downloads/Krita_Dev.mobileprovision \
  --identity "Apple Development: Your Name (XXXXXXXXXX)" \
  --install <device-id>
```

Development profiles expire after a year; re-sign with a fresh profile then.
TestFlight is an option later; it needs App Store Connect setup and
distribution signing.

## 6. First-run checks on her iPad

- [ ] Pencil: pressure, tilt, palm rejection, double-tap.
- [ ] Draw for an hour without a crash.
- [ ] Save `.kra` to iCloud Drive and Google Drive from the Files picker.
- [ ] Open that file in Krita 5.3 on the Mac and Windows laptop, edit, reopen
      on the iPad. LibrePaint is based on Krita 6.1-prealpha, so check that
      layers and text survive the trip both ways.
- [ ] Rotate the iPad, background the app, come back.
- [ ] Note every UI pain point for [ipad-ui.md](ipad-ui.md).
