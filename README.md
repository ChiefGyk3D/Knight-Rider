# Knight Rider

Read-only, allowlist-only lookups of Tor onion services and I2P eepsites, for defensive darknet OSINT.
It is meant to replace an ordinary browser lookup when an AI assistant needs to check a hidden service.
Page content comes back as sanitized plain text and is treated as untrusted data, never as instructions.

**Status: design phase. Nothing runs against the real Tor or I2P networks yet.** This repository holds the
baseline (license, policy, CI) and, later, the design and threat model. There is no fetching code.

## Networks

Tor onion services and I2P eepsites are both first-class. The allowlist, the request log and the sanitizer
treat the two networks the same way. Each tier below will document which networks it can reach and how; a
tier that cannot reach one of them says so plainly.

## Three isolation tiers

One interface, three backends, so a person can pick the level of isolation they are comfortable with:

1. **Tor Browser**, driven directly. The weakest isolation of the three.
2. **A container** with a Tor daemon (and optionally i2pd) and no other network route.
3. **A Whonix Gateway plus Workstation** under KVM/QEMU/libvirt. The strongest isolation.

Build order is container first, then the Whonix control wrapper, then Tor Browser. Each tier documents what it
does and does not protect.

## Rules that never change

- **Read-only.** No forms, no search boxes, no executing downloads, no images or files.
- **Allowlist-only, and private.** Default deny: only destinations on the user's own allowlist are fetched.
  The allowlist is the user's private data and is read from a configured path outside this repository.
- **No addresses in this repository.** No onion or I2P addresses in code, docs, tests, issues or examples.
  Placeholders only. A CI check enforces it.
- **Caps and logs.** Size and time caps, request logging, ephemeral sessions, and nothing inside the sandbox
  can reach the user's repositories, secrets or tokens.
- **Fetched content is data.** Whatever a page says, it is never an instruction to the assistant.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md). Report vulnerabilities privately, not
in a public issue.

## License

Apache-2.0. See [LICENSE](LICENSE).
