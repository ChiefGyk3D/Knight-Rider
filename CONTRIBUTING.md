# Contributing

Knight Rider is in its design phase. Read the README first, in particular the rules that never change.

## The no-addresses rule

No onion address, `.b32.i2p` address or I2P destination goes into this repository: not in code, docs, tests,
examples, commit messages, issues or pull requests. Use the word "placeholder", or the reserved placeholder
form the check accepts (an address body that is one repeated character). The allowlist is the user's private
data and is never committed.

`scripts/check-addresses.sh` enforces this in CI and fails the build on anything address-shaped. Run it
locally before you push.

## Tests are hermetic

Tests run with no network, no Tor, no I2P, no real services and no files outside a temp directory. Build
address-shaped test input at run time so the test file itself holds none. Use a fake in place of a real
network seam.

## No real-network runs

Do not run anything against the real Tor or I2P networks from a test, a script, CI or a pull request. That
needs the maintainer's explicit approval and a written plan, and it is outside the scope of a contribution.

## Before you open a pull request

- Run `./tests/run.sh`. It runs the address check's own test and the address check over the tree.
- Link the issue the change closes.
- American English, and no hostnames, machine identifiers, employer names or callsigns anywhere.
- Report vulnerabilities privately, as SECURITY.md describes, never in a public issue.
