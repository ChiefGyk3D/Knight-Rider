# Security Policy for `ChiefGyk3D/Knight-Rider`

## Supported Versions

There is no release yet. The project is in its design phase and nothing runs against the real networks.
Once a release exists, the latest tagged release is supported and fixes land on `main` first.

## Reporting a Vulnerability

Report vulnerabilities through
[GitHub private vulnerability reporting](https://github.com/ChiefGyk3D/Knight-Rider/security/advisories/new).
Do not open a public issue. Include the affected component, expected versus actual behavior, and reproduction
steps. Please do not include real onion or I2P addresses in a report; describe the shape instead.

Unfixed security detail stays private until the fix merges. A public issue says only that hardening is
tracked; the item list, file names and attack path stay in the private report until then.

## Scope

- The fetch path, the allowlist handling, the sanitizer and the isolation tiers, once they exist.
- Any way for fetched content to act as an instruction, escape a size or time cap, or reach the user's
  repositories, secrets or tokens from inside a sandbox.
- Vulnerabilities in upstream software this project drives (Tor, Tor Browser, i2pd, Whonix) belong with
  that upstream project.

## What to Expect

This project has one maintainer. Expect acknowledgement within a week, followed by a fix or written
assessment. There is no bounty. Reports are credited unless you decline.
