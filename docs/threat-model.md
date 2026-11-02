# Knight Rider threat model

Status: draft for the maintainer, written 2026-11-02 for issue #8 (epic #1, design #2). It is evidence for a decision,
not a verdict, and not a security audit. A Daybreak-tier review follows before approval; unfixed detail from that review
stays in a private tracker, not here. The machine-readable companion is
[`docs/threat-model/knight-rider.threat-dragon.json`](threat-model/knight-rider.threat-dragon.json) (OWASP Threat Dragon v2,
checked by the `threat-model` workflow from git-your-ship-together).

This is a public repository. The model names classes of weakness and the control for each. It contains no step-by-step
attack, no onion or I2P address, and no allowlist content.

## How to read the evidence marks

- **[V]** verified: I read the source on 2026-11-02. Sources are named. Where a page was read through a summarizing
  fetch, that is said, and the page itself should be read before anyone relies on the line.
- **[W]** the maintainer's wiki states it, citing a project page the wiki author read on 2026-10-31 or 2026-11-01. I read
  the wiki on 2026-11-02, not the upstream page. Second-hand.
- **[I]** inferred by me from the design and general security knowledge. To verify before the design relies on it.
- **[D]** a decision recorded in issues #1, #2 or #4 (maintainer, 2026-11-01 and 2026-11-02).

Nothing in this model was run. No Tor, I2P, browser, container or VM was started to write it.

## Scope

In scope: Phase 1 (the read-only, allowlist-only fetcher in three tiers) and the Phase 2 discovery lane as far as it
touches the same boundaries. Covered by reference only: the Phase 2 safety gate (#4) owns abuse filtering,
stop-and-report and purge; the optional authenticated mode has no design and is therefore not modeled (see
"Not covered").

## Design choices this model assumes

The design document (#7) is being written in parallel. If it differs from any line below, the model must be revised, and
the line that differs is the place to start.

| # | Assumption | Source |
|---|---|---|
| D1 | One interface, three backends: Tor Browser driven directly (T1), a container tier with a Tor daemon and optionally i2pd (T2), a Whonix Gateway plus Workstation under KVM/libvirt (T3). | [D] #1, #2 |
| D2 | Claude is the consumer, through a skill or MCP tool. The tool returns sanitized plain text, never raw markup, images or files. | [D] #1, #2 |
| D3 | Default deny. The allowlist is a file the tool reads from a configured path, kept in the maintainer's private synced config. The repository ships only a placeholder example. Agents never edit it. | [D] #2 |
| D4 | Size and time caps, request logging, ephemeral sessions reverted to a clean state after each run, and no repos, secrets or tokens reachable from inside the sandbox. | [D] #2 |
| D5 | The Whonix tier is driven through a restricted verb set: revert to a clean snapshot, run an allowed fetch, take a screenshot. Never an open shell. | [D] #2 |
| D6 | The Whonix host is a local machine now; later the always-on Ubuntu box or an on-demand VM on a Proxmox cluster. The control wrapper takes the host as configuration. | [D] #2 |
| D7 | Discovery (Phase 2): one hop from an allowlisted page, record only (liveness, title, category, public source, confidence), never page bodies. Promotion to the allowlist is a human act. | [D] #2, #4 |
| D8 | The authenticated mode is off by default, never ships enabled, and is not designed until its own safety gate is approved. | [D] #1, #2 |
| D9 | Nothing runs against the real Tor or I2P networks until the maintainer approves it; Phase 1 tests are hermetic with the network stubbed. | [D] #1, #2 |
| A1 | **Assumed, not decided:** in the container tier the network-facing daemons (Tor, i2pd) run in one container and the fetch-and-sanitize worker runs in another that sits on an internal network with a route only to the daemons' local proxy ports. "No other network route" is then a property of the worker, because a daemon must itself reach the internet. | [I] |
| A2 | **Assumed:** the parser and sanitizer run inside the sandbox, and only a length-capped UTF-8 text envelope crosses to the host. | [I] |
| A3 | **Assumed:** the tool's single entry point takes one destination per call and no free-form command text. | [I] |
| A4 | **Assumed:** the tool is client-only. It never publishes an onion service or an I2P hidden service. | [I] |

## What each tier can reach (verified where it could be)

The issue asks that the design not claim network reach it has not verified.

| Tier | Tor onion services | I2P eepsites | Evidence |
|---|---|---|---|
| T1 Tor Browser direct | Yes | **No by itself.** A separate I2P router on the host is needed, or this tier is Tor-only. | [D] #1 says so. A host-side router would reveal the host to I2P peers directly [I] (see K03). |
| T2 Container | Yes, with a Tor daemon | Yes, with i2pd | [D] #1. |
| T3 Whonix | Yes | Documented but **community-supported only**. The preferred setup runs an I2P router inside the Workstation with its traffic going through Tor; an I2P router on the Gateway is called untested and experimental by Whonix. | [V] Whonix wiki, I2P page, fetched 2026-11-02 through a summarizing fetch (no modified date shown on the page; permanent revision 107209). |

The same Whonix page lists caveats that matter here [V, same fetch]: I2P has no stream isolation, so visits to eepsites
are linkable and fingerprintable; the required browser configuration changes weaken the browser fingerprint, so that
browser should be used only for I2P; the proxy setting that makes this work breaks onion-service connections in the same
browser; the I2P developers do not really support I2P over Tor. Consequence for the design: in the Whonix tier, use one
fetch profile per network, not one browser for both.

## Assets

| ID | Asset | Class | Why it matters |
|---|---|---|---|
| A-1 | The maintainer's real network location and identity | Personal, sensitive | Anonymity is the point of the networks; losing it costs safety and legal footing. |
| A-2 | The host and everything the maintainer's account can reach: repositories, tokens, the Claude login, other credentials | Credentials | A sandbox escape converts a page visit into account compromise. |
| A-3 | The consuming AI session and its tool access | Integrity | Hostile page text aims at it; whatever tools it holds, an injected instruction can try to use. |
| A-4 | The allowlist (private) | Private, sensitive | Its contents reveal what the maintainer researches; its integrity decides what the tool may touch. |
| A-5 | The request log | Private, sensitive | A record of destinations and times. A target for theft, and for accidental publication. |
| A-6 | Discovery metadata (Phase 2): service identifiers, titles, categories, sources | Private, sensitive; possibly legally sensitive | Identifiers of services are the content of the database. |
| A-7 | Integrity of what the tool reports | Integrity | OSINT conclusions rest on it. |
| A-8 | The maintainer's legal and personal safety around abusive content | Safety | Stored or transcribed abusive text is a liability (gate #4). |
| A-9 | Repository and release integrity, and the public repository's cleanliness (no addresses, no unfixed detail) | Integrity | Public project; a leaked address or exploit detail cannot be unwritten. |
| A-10 | Availability of the tool, disk and quota | Availability | Lower value, but a stuck or flooded fetch blocks work. |

## Actors

| Actor | Capability | Prerequisite to act |
|---|---|---|
| Page author or service operator | Controls everything a fetched page contains and how the server behaves (timing, size, redirects). Aims text at the AI, bytes at the parser, and possibly exploits at the browser. | Content on a destination the user allowlisted or a lead the discovery lane records. No credential. |
| Third-party content on an allowlisted site | Comments, listings, profiles and mirrored text written by anyone | Account on that site. No relation to the operator. |
| The consuming AI, once injected | Calls the tool with chosen arguments; may try to persuade the maintainer | Hostile text already in its context |
| A local process or agent running as the maintainer's user | Reads and writes files the user can: allowlist, log, config | Code execution as that user (including after a T1 escape) |
| Network adversary | Watches both ends, runs relays or I2P floodfills, controls an AS | Position on the network; patience |
| Upstream compromise | Malicious or broken Tor Browser, Tor, i2pd, Whonix image, base image or dependency | A successful supply-chain event |
| Repository contributor or reader | Opens PRs and issues; reads everything public | A GitHub account |
| The maintainer, under pressure or by mistake | Widens the allowlist, runs the wrong tier, publishes a log | None |

## Trust boundaries

| ID | Boundary | Crossing data |
|---|---|---|
| TB1 | Consuming AI and the tool's entry point | Tool arguments in; sanitized text out |
| TB2 | Tool core and the private configuration (allowlist, log path, host settings) | File reads and writes as one user |
| TB3 | Tool core and each tier's control channel | The restricted verbs and their arguments |
| TB4 | The fetch sandbox and the Tor/I2P networks | Proxied requests and responses |
| TB5 | The fetch sandbox and its host (browser sandbox, container, hypervisor) | Everything the isolation is supposed to stop |
| TB6 | The tool and its stored data (log, discovery database) | Strings derived from hostile pages |
| TB7 | The private machine and the public repository, issues and any sync | Files, text, logs |
| TB8 | Upstream release sources and the sandbox images | Binaries, images, packages |

The highest-value boundary is TB1/TB4 together: page bytes travel from an adversary to a model that may hold tools,
with Knight Rider as the only filter between them.

## Risk register

Rank orders by impact first, then by what the actor needs before the attack works. A heavy prerequisite lowers a
high-impact risk below a moderate one that anyone can reach. Severity is Critical, High, Medium or Low. Verification
status: **planned** means the test or check does not exist yet (the repository today contains only the address check).

| Rank | ID | Risk | Severity | Prerequisite | Mitigation (short) | Verification status |
|---|---|---|---|---|---|---|
| 1 | K01 | Prompt injection: page text aimed at the consuming AI | High | Any text on any fetched page; no credential | Data envelope, text-only output, sanitizer, consumer privilege separation, no write verbs | planned; partly outside this repo |
| 2 | K02 | Sandbox escape, per tier | Critical | A working exploit chain delivered by a page (T1: one step; T3: several) | Per-tier hardening, no secrets inside, dedicated user or host, ephemeral | planned |
| 3 | K03 | Real IP or identity leak | High | Page-controlled resource, client bug, or a mis-wired network | Fail-closed network, remote name resolution, no direct route from the worker, T3 for the strongest case | planned |
| 4 | K04 | Allowlist bypass, tampering or widening | High | A parser flaw, a redirect, write access as the user, or persuading the maintainer | Strict normalized match, redirects re-checked, read-only permission, out-of-band edits only | planned |
| 5 | K05 | Abusive content met, stored or transcribed | High | Fetching a page; no attacker needed | Text-only, nothing persisted, tight caps; the stop-and-report rule is gate #4 | gate #4 pending |
| 6 | K06 | Control-channel abuse: restricted verbs turned into a shell | High | Influence over tool arguments (an injected AI) | Fixed verbs, argument vectors, schema validation, no free-form guest commands | planned |
| 7 | K07 | The log and stored data as a target | Medium | Local read access, or an accidental publish | Outside the repository, mode 0600, no bodies, retention, never in sync paths | planned; address check exists |
| 8 | K08 | Second-order injection: stored titles and log lines re-read by the AI | Medium | A page that sets its own title or text; later a read of the store | Treat stored strings as untrusted at read time, same envelope, escaping | planned |
| 9 | K09 | Supply chain: browser, daemons, images, dependencies | High | A compromised upstream release | Pin by digest, verify signatures, scan, update on a schedule | planned |
| 10 | K10 | The Whonix host question | High | A VM escape, or credentials left on the shared host | Dedicated host or separate hypervisor, least-privilege libvirt user, named domains only | maintainer decision |
| 11 | K11 | Hostile bytes parsed in the core | Medium | A page, a malformed response | Parse only inside the sandbox, memory-safe parser, fuzz | planned |
| 12 | K12 | Ephemerality fails: state survives a run or links runs | Medium | A prior hostile page or a revert failure | Revert and verify per run, fresh profile, per-run circuits | planned |
| 13 | K13 | The tool is distinguishable or can be cloaked against | Medium | An operator who profiles visitors | Stock configuration, per-network profiles, request discipline; accepted in part | inferred; manual |
| 14 | K14 | Network adversary: correlation, malicious relays, guard discovery, honeypot operators | Medium | Position at both ends or a controlled relay | Fewer and smaller requests, client-only, no long-lived services; accepted | not testable here |
| 15 | K15 | Resource exhaustion by a page or server | Low | A page or a slow server | Streaming byte cap, wall-clock cap, redirect cap, tmpfs limits | planned |
| 16 | K16 | Intelligence integrity: lures, cloaked or poisoned pages | Medium | An operator who wants to mislead | Provenance in every result, confidence notes, no automated action on content | planned |
| 17 | K17 | Public repository leakage: addresses, allowlist content, unfixed detail | High | A contributor mistake or an agent's draft | Address check in CI, private tracker, placeholders only, SECURITY.md | **exists** |

Counts: 17 risks, 17 mitigations, 17 verifications (sections below).

## Findings that shape the design

**F1. Sanitizing cannot remove an instruction written in plain sentences.** A sanitizer strips markup, hidden text,
control and direction-override characters and enforces a cap. A paragraph of ordinary English that says "ignore your
earlier instructions" survives all of that, because it is just text. So K01 cannot be closed by Knight Rider alone. What
Knight Rider can do is make the data unmistakably data, remove every channel that makes injection easier (markup, links
rendered as tools, hidden text), offer no verb that writes or acts, and require the consumer to read results in a session
that holds no write tools. [I] The wiki's own framing agrees that the dangerous part is the program on the other side of
the interface [W, Browsing Setups page].

**F2. The tiers differ most on what a breach costs, not on how likely it is.** Tor Browser's page-facing code is the same
in T1 and T3 (Whonix runs Tor Browser in the Workstation [W]); what changes is what surrounds it.

**F3. The Tor-over-I2P question is not symmetric.** A Tor daemon and i2pd both connect directly from the network-facing
container to the internet, so the "no other route" claim holds for the worker, not for the daemon container (A1). i2pd
also takes part in the I2P network as a router, so by default the host's address is visible to I2P peers, unlike a pure
Tor client's relationship with its guard [W: "Every participant is a router"; no official entry and exit points,
How I2P Works page]. Whether to route I2P through Tor as Whonix documents is a design choice with a cost (no stream
isolation, community support) that the design should state.

**F4. The log and the discovery database hold the most sensitive asset the project creates**, the list of what the
maintainer looked at, and the second-order injection route through them (K08) is easy to miss.

**F5. The transcript is a data store.** Whatever the tool returns becomes part of the consuming AI's conversation, which
is kept by the AI client (and its provider) under their own retention. "Nothing stored" for page text is therefore true
of Knight Rider, not of the whole path. [I] This matters most for K05.

## Risks in detail

Each entry: abuse case, impact, prerequisites, mitigation, verification, residual risk, and what follows if a sandbox is
breached where that applies. "Test" names the Phase 1 hermetic test to write; none of these exist yet except where
stated.

### K01. Prompt injection: page text aimed at the consuming AI

- **Abuse case.** An operator, or anyone who can place text on an allowlisted page, writes text meant to be obeyed by the
  model that reads the result: to call other tools, to disclose context, to ask the maintainer to widen the allowlist, to
  produce a false report. Hidden or oddly encoded text is a second form; so are text shaped like a tool result or a
  system message.
- **Impact.** High. It reaches whatever tools the consumer holds (repositories, tokens, shell). The sandbox does not
  help: the data leaves the sandbox by design.
- **Prerequisites.** None beyond text on a page the tool fetches. No credential, no exploit.
- **Mitigation.**
  1. The tool returns a fixed envelope: provenance header (network, normalized destination, fetch time, byte count,
     truncation flag) and the body as a quoted data block, with a fixed statement that the body is untrusted. The
     envelope is built by the tool, never by page text.
  2. Output is plain text only. No HTML, no markdown links, no images or files. Control characters, bidirectional
     overrides, zero-width and private-use characters are removed or made visible. Text hidden by markup (display
     tricks, comments, attributes) is not extracted unless the policy says so.
  3. No verb writes, posts, follows a link or changes configuration. Links found on a page are returned as inert text
     and cannot be passed to the fetch verb without passing the allowlist (K04).
  4. The skill or MCP tool that wraps Knight Rider tells the consumer to treat results as data, and the documentation
     recommends reading results in a session or subagent that holds no write-capable tools and returning only a short
     structured summary to the main session. [I] This part is advice and a skill-level control; it is outside this
     repository's code.
  5. A hard cap on output size limits how much room an injection has.
- **Verification.** Test (planned): a fixture corpus of page classes (hidden text, direction overrides, fake envelope
  or fake tool-result text, oversize, mixed encodings) run through the sanitizer; assert the output contains no markup
  or control characters, that the envelope is intact and unique, that the cap holds, and that fixture text shaped like
  an envelope is escaped. Test (planned): the fetch verb refuses a destination that appears only in page text. Review
  (planned): the Daybreak-tier reviewer attacks the envelope and the sanitizer.
- **Residual.** Plain-language instructions pass (F1). Reduced by consumer-side privilege separation, which the
  maintainer controls but this repository does not. Reopen if the consumer is ever given write tools in the same session
  that reads results, or if a result is ever fed to another tool's arguments automatically.

### K02. Sandbox escape, per tier

Treat each tier's isolation as breakable. What follows if it breaks:

| Tier | The isolation | If it is breached |
|---|---|---|
| T1 Tor Browser direct | The browser's own content sandbox and the operating-system user. The browser and every other program on the machine share one trust boundary [W, Browsing Setups page]. | Code runs as the user who started it. If that is the maintainer's normal account, everything in A-2 is exposed, along with the allowlist and logs, and the real address is known to the attacker. This is the weakest tier by design [D]. |
| T2 Container | Namespaces, capability and syscall filtering, an internal network for the worker (A1). | Breach of the worker alone: the attacker can use the local proxy ports (traffic leaves as Tor or I2P traffic, not as the maintainer's address), can forge result text (K01), and can attack the control channel (K06). It reaches no secret if none is mounted. A container escape reaches the host as the container runtime's user: root for a root-run daemon, the maintainer's own user for rootless. Breach of the daemon container reveals the real address. |
| T3 Whonix | Two VMs; the Workstation reaches only the Gateway; the host runs the hypervisor. | Breach of the Workstation: by Whonix's design the attacker still does not learn the real address [W, project claim, untested by the wiki author]; the attacker can forge results and attack the control channel. A hypervisor escape reaches the host. A compromised host compromises every VM on it [W, Whonix Warning page]. A compromised Gateway reveals the real address. |

- **Impact.** Critical in every tier once the boundary is crossed: access to the host account (A-2).
- **Prerequisites.** A working exploit chain for the browser (all tiers) plus, for T2 and T3, a second one for the
  container runtime or hypervisor. The first stage is delivered by any page. Heavy for T2 and T3, light for T1.
- **Mitigation.** Shared: no secret, token, repository, socket or host directory is ever mounted or reachable inside any
  sandbox; the sandbox user is not root; sessions are ephemeral (K12); browsers and engines are kept current (K09). T1: run
  only under a dedicated OS account that holds none of the maintainer's credentials, with the home directory of the
  maintainer unreachable [I]; document that otherwise T1 equals the daily account. T2: rootless runtime, all capabilities
  dropped, no new privileges, read-only root filesystem, size-limited tmpfs, no host or runtime sockets mounted, no
  privileged mode, default syscall filter kept, internal-only network for the worker. T3: no shared folders, no
  clipboard or display channel to the host that the verb set does not need, no USB or device passthrough, the guest
  agent speaks only the verb protocol, the libvirt domain definitions are generated by the wrapper and not editable
  from the guest, and the host choice in K10.
- **Verification.** Test (planned): the wrapper generates the container and domain definitions from configuration and
  the test asserts the dangerous settings are absent (privileged, host mounts, runtime sockets, added capabilities,
  device passthrough, shared folders, extra network attachments), failing red if any appears. Command (planned, after
  the maintainer approves a run): a tool-supplied self-check lists what the sandbox can see and reach, and the output is
  compared with an expected list.
- **Residual.** An unpatched browser or hypervisor flaw defeats any of this. T1 remains the weakest and is accepted by
  decision [D]. Reopen on any published escape for the engines in use.

### K03. Real IP or identity leak

- **Abuse case.** A page triggers a request that does not use the anonymity network; a name is resolved outside the
  proxy; a program in the sandbox ignores proxy settings; a client bug exposes the address; a mis-wired network gives the
  worker a direct route; a document opened by another program fetches a resource outside the proxy. The Tor Project says
  Tor protects only applications configured to use it, and that other programs can reveal the non-Tor address [W,
  Browsing Setups page]. A different case: the router for I2P in T1 or T2 connects to I2P peers directly, so the host's
  address is visible to them [W, How I2P Works page; I for the tier consequence].
- **Impact.** High: A-1.
- **Prerequisites.** A page that causes a request (any page); a mis-wiring or a client bug.
- **Mitigation.** The worker has no route except the local proxy (A1; T3: the Workstation reaches only the Gateway [W]).
  Name resolution is done by the proxy (SOCKS with remote resolution) and never locally. The fetch path opens no other
  process: no external viewers, no plugins, no document handlers. Non-text content types are refused (K15). T1 is
  documented as the tier where a bug can leak the address (the wiki's "browser-only model" argument). The design states
  whether I2P is reached directly (the host is visible to I2P peers) or through Tor (the Whonix-documented preferred
  setup, with its stream-isolation cost [V]). i2pd is configured not to publish itself or relay transit traffic where its
  configuration allows [I; verify against the i2pd documentation].
- **Verification.** Test (planned): the generated network configuration for the worker has no default route and no
  resolver; a stub proxy that records every connection shows the fetcher sends only remote-resolved names to it; a name
  that cannot be resolved by the proxy fails closed. Command (planned, after approval): from inside the worker, confirm
  a direct connection attempt fails and a lookup of a public name fails.
- **Residual.** T1: any browser flaw can leak. All tiers: the host's own network sees that Tor or I2P is used [W].

### K04. Allowlist bypass, tampering or widening

- **Abuse case.** (a) A look-alike destination passes the match: a different host with the same visible prefix, user
  information in the URL, a trailing dot, case or encoding variants, an unexpected port or scheme. (b) An allowlisted page
  redirects to a destination that is not on the list, or to the ordinary internet. (c) A process or an injected agent
  running as the maintainer's user edits the allowlist file. (d) A page, or the injected AI, persuades the maintainer to
  add a destination.
- **Impact.** High: it removes default deny, which every other control assumes.
- **Prerequisites.** (a) and (b): a page and a parser difference. (c): code execution as the user, which T1 breach or an
  agent with shell gives. (d): a plausible message.
- **Mitigation.** Parse once into a canonical host, port and scheme; match exactly against canonical entries; reject
  anything the parser cannot canonicalize. Allow only the schemes the networks need. Redirects are not followed
  automatically; each hop is re-checked against the allowlist and counted against a small cap; a redirect to a
  non-allowlisted or non-network destination is refused. The tool has no verb that edits the allowlist and the example
  file in the repository is a placeholder. At startup the tool refuses a file that is group- or world-writable or that
  lies inside a repository; each log line carries the allowlist's digest so a change is visible in the record. Promotion
  of a discovered destination is a human act made outside any tool the AI can call (D7). The denial message gives no
  hint about how to widen the list. An optional hardening: sign the allowlist with a key held off the machine, in the
  manner of SAFO's signed approvals [I].
- **Verification.** Test (planned): a table of hostile destination forms, each expected to be denied, and of valid forms,
  each expected to pass; a redirect-to-forbidden test and a redirect-loop test; a startup test with a writable file and
  a file inside a repository, expected to refuse. Command: `stat -c '%a %U' <allowlist path>` expected to show no group or
  world write. Test (planned): the log digest changes when the file changes.
- **Residual.** The same user can still write the file (c). The digest makes it visible, not impossible; a signature or
  off-box copy closes more of it. Reopen if the allowlist format gains patterns or wildcards.

### K05. Abusive content met, stored or transcribed

- **Abuse case.** A fetched text page contains abusive material or a credible threat; or an identifier of such a page is
  stored in the discovery database; or text is copied into the consumer's transcript.
- **Impact.** High for the maintainer (A-8), whatever the page's reachability.
- **Prerequisites.** None. Fetching a page is enough, which is why this is ranked above the engineering risks that need a
  flaw first.
- **Mitigation.** Owned by the Phase 2 safety gate (#4): the abuse filter, the stop-and-report rule, the purge procedure
  and the named reporting channel. For Phase 1, the core limits the exposure: text only, no images or files, caps, nothing
  persisted from a page body, memory or size-limited tmpfs inside the sandbox that is destroyed at the end of the run
  (K12). Be explicit in the design that the consumer's transcript is outside Knight Rider's storage (F5).
- **Verification.** Phase 1: Test (planned) that a run leaves no page body on any persistent path (log, database, cache)
  and that non-text types are refused. The gate's own checks belong to #4, which is not approved yet.
- **Residual.** The gate does not exist yet; until it does, discovery must not run. The transcript path cannot be
  controlled from here.

### K06. Control-channel abuse: the restricted verbs turned into a shell

- **Abuse case.** The verbs take arguments (a destination, a snapshot name, a path). A crafted argument becomes an extra
  option, a second command, or a path outside the intended area; or a compromised guest sends the host a message that the
  host mishandles.
- **Impact.** High: it turns the narrow interface into code execution on the host or guest.
- **Prerequisites.** Control of a tool argument (an injected AI, K01), or a compromised guest for the reverse direction.
- **Mitigation.** A closed set of verbs (D5), each with a schema; arguments are validated, then passed as an argument
  vector, never assembled into a shell string; values that begin like an option are rejected; names such as snapshots
  and domains come from configuration, not from the caller; length limits; the guest side accepts only schema-valid
  messages and answers with bounded text; the host treats everything from the guest as untrusted (A2).
- **Verification.** Test (planned): hostile-argument fixtures (option-like, whitespace and newline, shell metacharacters,
  path traversal, oversize, wrong type) against every verb, expected to be rejected before any process is started, using
  a stub that fails the test if a process is spawned. Test (planned): a guest-message fuzz against the host parser.
- **Residual.** Parser bugs remain possible; keep the channel small and review it first.

### K07. The log and stored data as a target

- **Abuse case.** The request log or the discovery database is read by another process, backed up to a remote, swept
  into the synced configuration, or committed. It lists the maintainer's interests and, in Phase 2, service identifiers.
  Logs also gather page-derived strings (K08).
- **Impact.** Medium: sensitive, and a public leak cannot be undone.
- **Prerequisites.** Local read access as the user, or an accidental commit or sync. The address check does not cover
  the private machine.
- **Mitigation.** The log and database live outside the repository and outside the directories `dotsync` and similar
  tools push; file mode 0600 in a 0700 directory; no page bodies, query strings, cookies or headers in the log; a
  bounded retention with a documented purge; the database encrypted at rest or kept on an encrypted volume [I]; the
  repository's `.gitignore` excludes any local state directory; the tool refuses a log path inside a repository.
- **Verification.** Test (planned): a run against stubs writes lines containing no body, header or cookie text, only
  the defined fields; the tool refuses a log path inside a git work tree. Command: `./scripts/check-addresses.sh`
  exits 0 on every tracked file (exists). Command: `git check-ignore -v <state directory>` shows the ignore rule.
- **Residual.** Same-user read access, and a person who copies the log by hand. Reopen when the database exists.

### K08. Second-order injection: stored titles and log lines re-read by the AI

- **Abuse case.** A page sets a title or other short field that the discovery lane records. Later the AI reads the
  database or log (for a summary or digest) and the stored string carries instructions or forged structure. The
  hostile text has been laundered through the tool's own storage and now looks like the tool's own output. A log line
  can also be forged if page text can contain a newline.
- **Impact.** Medium (the same effect as K01, delayed, and the maintainer trusts it more).
- **Prerequisites.** A page that sets the field; a later read of the store.
- **Mitigation.** Fields are normalized, length-capped and stripped of control characters at write time; the log format
  escapes newlines and delimiters; every read path that returns stored strings to the AI uses the K01 envelope and says
  the fields are untrusted; counts and categories are computed by code, with the model asked only for prose [I].
- **Verification.** Test (planned): a title containing a newline, a fake log line, a fake envelope and control
  characters is stored; the log still parses as one line per event; a read returns it escaped inside the envelope.
- **Residual.** Plain-language instructions again (F1).

### K09. Supply chain: browser, daemons, images, dependencies

- **Abuse case.** A tampered or outdated Tor Browser, Tor, i2pd, Whonix image, container base image or build dependency
  is installed; or an old one is left in place and a published flaw is used against it.
- **Impact.** High: it runs inside the sandbox and, through K02, beyond it.
- **Prerequisites.** A compromised upstream or download path, or neglect.
- **Mitigation.** Images pinned by digest; downloads verified against the vendor's published signatures and the
  procedure written down with its date [I; to verify against each vendor's page at the time]; no `latest` tags;
  dependency and image scanning through the `security` workflow of git-your-ship-together; a scheduled update with a
  recorded date, because an out-of-date browser is itself a risk (K02); the Whonix images obtained and verified only by the
  documented method.
- **Verification.** Check (planned): a CI step that fails on an unpinned image reference or a floating tag. Command:
  `grep -rnE ':latest|@sha256:' <image definitions>` shows only pinned references. The existing `security` and
  Dependabot checks (the repository's CI already calls the `security` workflow).
- **Residual.** A compromised signing key or a zero-day. Reopen at every engine upgrade.

### K10. The Whonix host question

- **Abuse case.** The VM runs on a host that also holds the Claude login, repositories or other credentials (the
  double-duty plan for the always-on box [D]). A guest breach, hypervisor escape or a compromised libvirt connection then
  reaches them. The control wrapper's own credential to the hypervisor can create and destroy machines.
- **Impact.** High: A-2.
- **Prerequisites.** A hypervisor escape (heavy) or the wrapper's credential in the wrong hands (light).
- **Mitigation.** Prefer a host used only for these VMs; the Whonix project says safety is materially improved by a
  dedicated host [W, Warning page]. If the always-on box is shared, keep the Claude login and other credentials out of
  reach of the account that runs the VMs, or use a separate hypervisor host (the maintainer's note in #2). The wrapper
  connects as a dedicated account with rights only on the named Whonix domains (polkit or libvirt access control, [I]), over
  an authenticated, encrypted channel for a remote host; the host is configuration and nothing assumes the maintainer's
  layout (D6). Proxmox has its own API and would be a separate driver; whether libvirt covers it is not verified [I].
- **Verification.** Checklist the maintainer signs off before first run: which credentials exist on the host, which
  account runs the VMs, and the output of the access-control listing for that account. Test (planned): the wrapper
  refuses any domain name not in its configuration.
- **Residual.** Virtualization enlarges the trusted computing base [W, Whonix threat-model page, quoted by the wiki].
  This one is the maintainer's decision, not a code fix.

### K11. Hostile bytes parsed in the core

- **Abuse case.** A response is crafted to break the HTML, charset, compression or text-extraction code: deep nesting,
  huge inputs, decompression bombs, encodings that disagree, malformed headers.
- **Impact.** Medium: a parser bug in the host process would sit outside the sandbox.
- **Prerequisites.** A page or a server response.
- **Mitigation.** Parse and sanitize inside the sandbox (A2); the host validates only a bounded UTF-8 envelope; use a
  memory-safe language and a maintained parser; limit nesting, total size, and decompression ratio; refuse unknown
  encodings.
- **Verification.** Test (planned): property and fuzz tests with a time and memory budget; a bomb fixture that must
  stop at the cap.
- **Residual.** A sandbox-contained parser bug still lets the attacker forge output (K01).

### K12. Ephemerality fails: state survives a run or links runs

- **Abuse case.** A cookie, cache entry, service worker, profile file or compromised process survives from one fetch to
  the next; a snapshot revert silently fails; circuits are reused so two fetches are linked; in the Whonix I2P setup,
  visits are linkable because I2P has no stream isolation [V].
- **Impact.** Medium: it ties together visits and lets an earlier breach persist.
- **Prerequisites.** A prior hostile page, or a revert error.
- **Mitigation.** Revert to a clean snapshot after every run and verify it (state marker, not the revert command's exit
  code); fresh browser profile per run in T1; throwaway containers per run in T2; per-run circuits and isolation for Tor;
  the design says plainly that I2P visits are linkable in the Whonix path.
- **Verification.** Test (planned): the wrapper treats a revert that does not report success as failure and refuses the
  next fetch; a marker written in one run is absent in the next in the stubbed backend.
- **Residual.** Linkability on I2P through Tor stays [V].

### K13. The tool is distinguishable, or can be cloaked against

- **Abuse case.** An operator spots automation: a modified browser configuration (Whonix warns the I2P configuration
  weakens the fingerprint [V]), request cadence, no images, no scripts. They block, serve different content to it, or
  mark it for later correlation.
- **Impact.** Medium.
- **Prerequisites.** An operator who profiles visitors.
- **Mitigation.** Keep browser settings stock wherever possible; one profile per network; jittered cadence and a low
  request count; accept that a text-only reader differs from a person.
- **Verification.** Manual review only [I]; no test claims this.
- **Residual.** Accepted in part. Tor Browser itself says all users cannot be made identical [W].

### K14. Network adversary: correlation, malicious relays or floodfills, guard discovery, honeypots

- **Abuse case.** An observer of both ends correlates a fetch with a destination; malicious relays or I2P floodfills
  gather data; an allowlisted service is run to learn who looks at it.
- **Impact.** Medium for a client that fetches occasionally and publishes nothing.
- **Prerequisites.** Position at both ends, or a controlled relay or floodfill; sustained effort. Documented examples:
  the 2014 relay removal, correlation research, I2P's own threat-model page, and the recent floodfill-based work on
  hidden I2P services [W, How Tor Works and How I2P Works pages]. Guard discovery on onion services concerns services,
  and this tool is client-only (A4).
- **Mitigation.** Client-only (A4); no long-lived services; few, small requests; do not fetch at predictable times;
  no logged-in behavior.
- **Verification.** Not testable in this repository. The design states it as a non-goal, matching issue #1.
- **Residual.** Accepted. The sources agree that low-latency networks cannot reliably stop it [W].

### K15. Resource exhaustion by a page or a server

- **Abuse case.** An endless stream, a slow trickle, a redirect loop, a huge body, a compressed bomb, or many requests.
- **Impact.** Low: availability and disk.
- **Prerequisites.** A page or server.
- **Mitigation.** A byte cap enforced while streaming, a wall-clock cap per request and per run, a redirect cap, a
  concurrency limit, content-type allowlist (text types only), size-limited tmpfs, and a kill-and-revert on breach.
- **Verification.** Test (planned) against a stub server that streams forever, trickles, loops and bombs; each must stop
  at the cap with a distinct error.
- **Residual.** Low.

### K16. Intelligence integrity: lures, cloaked or poisoned pages

- **Abuse case.** A page tells the AI, or the human, what the operator wants believed; content differs by visitor; a
  page is a lure to move the analyst to a clearnet site or to widen the allowlist.
- **Impact.** Medium for the quality of the research.
- **Prerequisites.** An operator who wants to mislead.
- **Mitigation.** Provenance and time in every result; a field stating that the content is operator-controlled;
  no automated action on content; discovered leads only recorded (D7).
- **Verification.** Test (planned): results always carry the provenance header. Review by the maintainer.
- **Residual.** Judgment stays human.

### K17. Public repository leakage

- **Abuse case.** A real onion or I2P address, an allowlist entry, a log excerpt or unfixed exploit detail reaches a
  commit, issue, PR, test or wiki page, by a contributor or by an agent drafting text.
- **Impact.** High: public history cannot be unwritten; also legal and safety effects.
- **Prerequisites.** A mistake.
- **Mitigation.** `scripts/check-addresses.sh` over every tracked file in CI through `tests/run.sh`; the example
  allowlist uses placeholder forms only; `SECURITY.md` says unfixed detail goes to the private tracker; this model
  describes classes and no steps.
- **Verification.** Command: `./tests/run.sh` expected to print `all checks passed` and exit 0 (exists, run for this
  pull request). The unit test for the check is `tests/test_check_addresses.sh`.
- **Residual.** The check finds address-shaped strings, not an allowlist described in words or a log excerpt without an
  address. Review stays human.

## Guarantees and non-guarantees

What this design, once built as modeled, would aim to give: a destination not on the allowlist is not fetched (K04);
the worker has no direct route (K03); a run leaves no page body on disk (K05, K12); results arrive as a single labeled
envelope (K01); the log carries fields and no bodies (K07).

What it does not give: that a page cannot influence the AI (F1); that a browser or hypervisor flaw cannot be used (K02);
anonymity against a watcher of both ends (K14); safety on a host that shares credentials (K10); any control over the
consumer's transcript (F5).

## Residual risks that need a person to accept them

| Risk | Who accepts | Signal to reopen |
|---|---|---|
| Plain-language injection passes any sanitizer (K01) | The maintainer, with consumer-side separation | The consumer gains write tools in the reading session |
| T1 shares the account (K02) | The maintainer, already decided as weakest [D] | T1 is used on an account with credentials |
| Host shared with the Claude login (K10) | The maintainer | The always-on box takes the Whonix role |
| Correlation by a network adversary (K14) | The maintainer | The tool begins to publish or to run on a schedule |
| Transcript retention (F5) | The maintainer | Page text is pasted into any other system |
| I2P through Tor is community-supported and linkable [V] | The maintainer | The design selects that path |

## Not covered

- The optional authenticated mode (D8): no design exists, so no model. It adds credentials as an asset and a
  hardware-key or passkey approval path; it needs its own model when its safety gate is written.
- The Phase 2 gate's abuse filter, stop-and-report and purge (#4): referenced, not modeled.
- The legal position of fetching particular content in a particular place; no law was checked.
- Anything live: no network, router, browser, container or VM was run or probed.
- Source-level review: there is no code yet. The model describes the design as the issues state it; the Daybreak-tier
  review of the built Phase 1 is a separate step and is required before anything is installed on a host.
- The upstream project sources themselves: the wiki's citations were read second-hand, apart from the Whonix I2P page,
  which was read through a summarizing fetch.

## Keeping it honest

- Update this model in the same pull request as any change to a tier, the control verbs, the sanitizer, the log or the
  storage.
- The `threat-model` workflow checks the Threat Dragon file's shape and that the required topics (prompt injection,
  data leakage, tool abuse) appear. It cannot tell that the model is true.
- When the design document (#7) lands, reconcile the assumptions table first.

## Sources

- Issues #1, #2, #4, #8 in this repository, read 2026-11-02.
- The maintainer's wiki pages (local clone read 2026-11-02): Tor, I2P and the Darknet Without the Myths; The Browsing
  Setups Compared; How Tor Works in Depth; How I2P Works. They cite Tor Project, I2P project, Whonix, Tails and Qubes
  pages read 2026-10-31 and 2026-11-01.
- Whonix wiki, I2P page, fetched 2026-11-02 through a summarizing fetch.
- The git-your-ship-together `threat-model.yml` workflow and README section, and the SAFO threat model in
  `scrum-around-and-find-out/docs/`, read 2026-11-02 for the file's expected shape.
