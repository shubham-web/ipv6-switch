# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-21

First public release.

### Added

- Window showing connection mode (dual-stack, IPv4 only, IPv6 only, offline), local and public addresses.
- Switch to turn IPv6 off or back on (Automatic) for the active network service, with an administrator prompt when needed.
- Dock badge showing `v4`, `v6` or `v4+v6`.
- Auto-refresh every 15 seconds.
- Full-tunnel VPN support: when the default route goes through a VPN, the switch controls the physical service underneath.
- Universal (Apple silicon + Intel) release builds for macOS 13 and later.

[Unreleased]: https://github.com/shubham-web/ipv6-switch/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/shubham-web/ipv6-switch/releases/tag/v0.1.0
