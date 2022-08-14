# Security policy

IPv6 Switch changes system network settings and can run one command as root (after you approve the macOS administrator prompt), so security reports are taken seriously.

## Supported versions

Only the latest release gets security fixes.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Report them privately through [GitHub's private vulnerability reporting](https://github.com/shubham-web/ipv6-switch/security/advisories/new).

Please include:

- what the problem is and what an attacker could do with it
- steps to reproduce, or a proof of concept
- the app version and macOS version

You should get an acknowledgement within a few days. Once a fix is released, the advisory is published with credit to you, unless you'd rather stay anonymous.

## Scope

Examples of what counts:

- running commands or code with elevated privileges beyond the intended `networksetup -setv6off` / `-setv6automatic` call
- injection through network service names or command output
- the app sending data anywhere other than the ipify lookups described in the [README](README.md#privacy)

Out of scope: the release builds not being notarized (a known limitation), and problems that need an attacker who already controls your user account.
