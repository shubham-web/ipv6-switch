# Contributing to IPv6 Switch

Thanks for helping. This is a small project, so the process is light.

## Ways to help

- **Report a bug.** Use the [bug report form](https://github.com/shubham-web/ipv6-switch/issues/new?template=bug_report.yml). Network setups vary a lot, so the output of `route -n get default` and `networksetup -listnetworkserviceorder` is often what makes a bug fixable.
- **Suggest a feature.** Open a [feature request](https://github.com/shubham-web/ipv6-switch/issues/new?template=feature_request.yml) first for anything large, so we can agree on the approach before you write code.
- **Send a pull request.** Bug fixes, tests, docs and items from the [roadmap](README.md#roadmap) are all welcome.

## Development setup

You need macOS 13+ and Swift 6 (Xcode 16+ or the Command Line Tools). There are no other dependencies.

```sh
git clone https://github.com/shubham-web/ipv6-switch.git
cd ipv6-switch
make test     # run unit tests
make run      # build build/IPv6 Switch.app and open it
```

You can also open `Package.swift` in Xcode and run the `IPv6Switch` scheme. Running it that way skips the `.app` bundle, so there's no icon or Dock badge, but it's handy for debugging.

## Project layout

```
Sources/
  IPv6SwitchCore/       Network logic, no UI. Everything testable lives here.
    Parse.swift           Pure parsers for route/networksetup output and service selection
    NetworkSnapshot.swift Gathers the current state (runs the commands)
    IPv6Control.swift     Turns IPv6 on/off, with the admin prompt fallback
    PublicIP.swift        Public address lookups over IPv4 and IPv6
    Addresses.swift       Local interface addresses and IP validation
    Shell.swift           Runs a subprocess
  IPv6Switch/           The SwiftUI app (window, view model, Dock badge, debug-only demo mode)
Tests/IPv6SwitchCoreTests/  Unit tests (Swift Testing)
Support/Info.plist      App bundle metadata
scripts/build-app.sh    Builds and signs the .app bundle
scripts/make-icon.swift Draws the app icon at build time
scripts/screenshot.sh   Regenerates docs/screenshot-*.png
```

## Guidelines

- **Keep the core testable.** Put parsing and decision logic in `IPv6SwitchCore` as pure functions, and add a test using real command output. Captured output from an unusual setup (VPN, USB tethering, renamed services, a non-English system) makes a valuable test case.
- **Treat anything that runs as root carefully.** Never interpolate user-controlled strings, such as service names, into shell or AppleScript source. Pass them as arguments, as `IPv6Control.adminArguments` does.
- **Don't add dependencies** without discussing it first. The app is small on purpose.
- **Match the existing style.** Standard Swift naming, 4-space indentation, and comments that explain *why* rather than *what*.
- **One change per pull request**, with a clear description of what it does and how you tested it. If you changed behavior a user can see, update `README.md` and add a line under *Unreleased* in `CHANGELOG.md`.
- **If you change the UI, run `make screenshot`** to regenerate the README images. It runs a debug build in demo mode, which shows example addresses from the documentation ranges (so nobody's real IP ends up in the repo) and never changes network settings. You can also try demo mode by hand with `IPV6SWITCH_DEMO=dark swift run` (or `light`).

Before you open a pull request, check that these pass:

```sh
make test
make app
```

CI runs the same commands on every pull request.

## Releasing (maintainers)

1. Update `VERSION` and move the *Unreleased* notes in `CHANGELOG.md` under the new version.
2. Commit, then tag and push: `git tag v$(cat VERSION) && git push origin main --tags`.
3. The [release workflow](.github/workflows/release.yml) checks that the tag matches `VERSION`, runs the tests, builds a universal (Apple silicon + Intel) app and publishes the zip and its checksum to GitHub Releases.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). By taking part you agree to follow it.
