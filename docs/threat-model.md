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
| D5 | The Whonix tier is driven through the closed verb set in the Verb registry (revert to a clean snapshot, fetch, probe, and the operator-only screenshot). Never an open shell. The screenshot verb is operator-only: it writes to a private operator directory for the maintainer's diagnosis and is not exposed through the AI-facing tool, so no image ever crosses to the AI (consistent with D2). | [D] #2; the operator-only reading is an assumption [I] |
| D6 | The Whonix host is a local machine now; later the always-on Ubuntu box or an on-demand VM on a Proxmox cluster. The control wrapper takes the host as configuration. | [D] #2 |
| D7 | Discovery (Phase 2): one hop from an allowlisted page, record exactly three payload fields (liveness, title, category), keyed by the lead's canonical destination, and nothing else persisted (see K08), never page bodies. A recorded lead is never an input to further discovery. Promotion to the allowlist is a human act. Issue #1 also mentions a public source and a confidence note; this model leaves them out because #2 and #4 name three fields, and adding any is a decision for the maintainer. | [D] #2, #4 |
| D8 | The authenticated mode is off by default, never ships enabled, and is not designed until its own safety gate is approved. | [D] #1, #2 |
| D9 | Nothing runs against the real Tor or I2P networks until the maintainer approves it; Phase 1 tests are hermetic with the network stubbed. | [D] #1, #2 |
| A1 | **Assumed, not decided:** in the container tier the network-facing daemons (Tor, i2pd) run in one container and the fetch-and-sanitize worker runs in another that sits on an internal network with a route only to the daemons' local proxy ports. "No other network route" is then a property of the worker, because a daemon must itself reach the internet. | [I] |
| A2 | **Assumed:** the parser and sanitizer run inside the sandbox, and only a length-capped UTF-8 text envelope crosses to the host. | [I] |
| A3 | **Assumed:** the tool's single entry point takes one destination per call and no free-form command text. | [I] |
| A4 | **Assumed:** the tool is client-only. It never publishes an onion service or an I2P hidden service. | [I] |

## Verb registry (normative)

One list. Every table, test and diagram in this model that names a verb derives from it or is checked against it. A verb
that is not in this registry does not exist; a verb in it is covered by every test that says "every verb".

| Verb | Caller (who may invoke it) | Arguments | Reaches the guest | Notes |
|---|---|---|---|---|
| `fetch` | The AI-facing tool entry (and the controller on its behalf) | One destination, which must match the allowlist (K04) | Yes | Returns the sanitized text envelope |
| `status` | The AI-facing tool entry | None | No | Returns only the status of the current request and aggregate health counters; no history, destinations, times or paths (K07) |
| `probe` | The controller only; **never the AI** | One candidate destination, taken only under a single-use, run-bound capability (K04, K08) | Yes | Liveness, title and category only; no link extraction |
| `revert` | The controller only | None; the snapshot or image name comes from configuration | Yes (host acts on the guest's backing state) | Part of the one-fetch-per-instance lifecycle (K12) |
| `screenshot` | The operator only | None | Yes | Writes to a private operator directory; never crosses to the AI |
| `log` | The operator only | A bounded selector | No | Log inspection (K07); absent from the AI-facing tool |
| `paths` | The operator only | None | No | Prints effective storage paths (K07); absent from the AI-facing tool |

The AI-facing set is therefore exactly `fetch` and `status`. The controller-to-guest set is exactly `fetch`, `probe` and
`revert` (`screenshot` for the operator). Allowlist promotion is not a verb: it is a human act outside any tool (D7).

**Hypervisor operations** (T3), a second closed list that the wrapper may use against the hypervisor, and nothing else:
start, stop and destroy a **named** Workstation or Gateway domain; revert a named domain to its recorded clean snapshot;
read-only inspection of a named domain's effective definition and state (K02c, K12). There is no operation to create,
define, edit, enumerate unrelated objects, or touch networks, storage pools, secrets or the host itself.

**Derivation.** Planned `scripts/check-verbs`-style check: parse this registry, the Threat Dragon file's flow and
process descriptions, and the K04, K06, K07 and K11 test lists; fail if a verb appears in any of them that the registry
lacks, or a registry verb is missing from the K06 argument tests, the K11 schema tests or the verb-exposure test, or if
the AI-facing set in the code differs from `fetch` and `status`. The K06 hostile-argument tests and the K07 and K11
exposure tests are generated from the registry, so adding a verb adds its tests.

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
| A-4 | The allowlist (private), including every synced copy | Private, sensitive | Its contents reveal what the maintainer researches; its integrity decides what the tool may touch. |
| A-5 | The request log | Private, sensitive | A record of destinations and times. A target for theft, and for accidental publication. |
| A-6 | Discovery metadata (Phase 2): titles, liveness and categories of leads, keyed by the lead's canonical destination | Private, sensitive; possibly legally sensitive | Identifiers of services are the content of the database. |
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

Ten boundaries, drawn separately in the Threat Dragon file. In T2 and T3 each is a real wall. In T1 the browser, the
control wrapper and the host share one operating-system user, so TB4, TB5 and TB7 collapse into the account boundary (a
dedicated account is the mitigation, K02a).

| ID | Boundary | Crossing data |
|---|---|---|
| TB1 | The consuming AI and client, and the host-side core | Tool arguments in; the result envelope out |
| TB2 | The core and wrapper, and the private configuration (the allowlist) | Allowlist reads; writes by anyone with the same user |
| TB3 | The core, and the request log and discovery storage | Log and record writes, derived from hostile pages; later reads |
| TB4 | The core and wrapper, and each sandbox or VM guest | Control verbs in; the text envelope out |
| TB5 | The sandbox guest, and the network daemon or Gateway | Proxied requests and responses |
| TB6 | The daemon or Gateway, and the anonymity networks and services | Tor or I2P traffic; hostile page bytes |
| TB7 | The sandbox guest, and its host and hypervisor | Everything the isolation is supposed to stop |
| TB8 | The private machine, and the public repository and issues | Files, text, logs |
| TB10 | The private synced configuration store, and every machine holding a copy of the allowlist | The allowlist file itself, deliberately; copies, history and recovery copies (K18) |
| TB9 | Upstream artifacts, and the sandbox images and the host | Binaries, images, packages |

The highest-value crossing is TB6 to TB4 to TB1 in series: page bytes travel from an adversary, through the sandbox and
the host-side core, to a model that may hold tools. The host-side core sits outside the sandbox and must treat the
sandbox's output as hostile; the AI sits outside the core and must treat the core's output as data.

## Risk register

Rank orders by impact first, then by what the actor needs before the attack works. A heavy prerequisite lowers a
high-impact risk below a moderate one that anyone can reach. Severity is Critical, High, Medium or Low. The register is
sorted by rank; the detailed sections below follow ID order. Verification status: **planned** means the test or check
does not exist yet (the repository today contains only the address check).

| Rank | ID | Risk | Severity | Prerequisite | Mitigation (short) | Verification status |
|---|---|---|---|---|---|---|
| 1 | K01 | Prompt injection: page text aimed at the consuming AI | High | Any text on any fetched page; no credential | Data envelope, text-only output, sanitizer, consumer privilege separation, no write verbs | planned; partly outside this repo |
| 2 | K02a | T1: browser compromise reaches the user account | Critical | One browser exploit, delivered by a page | Dedicated OS account, confinement, positive host-observed inventory | planned |
| 3 | K02b | T2: worker breach, then container escape | Critical | A browser exploit, then a runtime escape | Rootless, positive host-observed inventory, daemon and worker split | planned |
| 4 | K02c | T3: Workstation, Gateway and hypervisor crossings | Critical | Browser exploit, then a VM-boundary or Gateway flaw | Generated domain definitions, host-observed effective inventory, host choice (K10) | planned |
| 5 | K03 | Real IP or identity leak | High | A page that triggers a request, a client bug or a wiring mistake | Tier-specific network invariants observed at the enforcement point | planned |
| 6 | K07 | Log and stored data leave the machine: backup, sync, commit, the AI transcript | High | A sync or backup job, a mistaken commit, or text that induces an injected AI to ask for the log | No AI-facing log verb, resolved paths checked, exclusions, exact schema, retention | planned |
| 7 | K18 | The private allowlist leaves the machine through its own sync | High | Compromise or misconfiguration of the sync channel or any copy, or a step that prints the file | Defined location and readers per copy, private minimal-scope store, no contents in outputs, readiness check | planned |
| 8 | K04 | Allowlist matching bypass, redirect, unbrokered page-initiated requests, or widening by persuasion | High | A parser difference, a redirect, an allowlisted page, or a plausible message | Canonical match, every request class brokered before dispatch, human-only promotion | planned |
| 9 | K17 | Public repository leakage: addresses, allowlist content, unfixed detail | High | A contributor or agent mistake | Address check in CI, private tracker, placeholders only | **exists** |
| 10 | K05 | Abusive content met, stored or transcribed | High | Fetching a page; no attacker needed | Text-only, nothing persisted; stop-and-report is gate #4 | gate #4 pending |
| 11 | K06 | Tool abuse: control-channel verbs turned into a shell | High | Influence over tool arguments (an injected AI) | Fixed verbs, argument vectors, schema validation | planned |
| 12 | K09 | Supply chain: browser, daemons, images, dependencies | High | A compromised or neglected upstream | Parse-and-fail pinning policy, separate provenance check | planned |
| 13 | K10 | The Whonix host question | High | A VM escape, or credentials left on the shared host | Dedicated host or hypervisor, least-privilege libvirt user | maintainer decision |
| 14 | K08 | Discovery lane: fan-out past one hop, and second-order injection | High | A page with a lead, a later read of the store | Declared persisted representation, one-hop rule, escaped reads | planned |
| 15 | K04b | Allowlist file substitution and same-user tampering | High | Same-user code execution (K02a gives it) | Constrained symlink-free resolution, descriptor read; same-user tampering accepted | planned; residual accepted |
| 16 | K12 | Ephemerality fails: state survives a run or links runs | Medium | A prior hostile page or a failed cleanup | One network transaction (fetch or probe) per instance, host-controlled evidence only, poisoned on any failure | planned |
| 17 | K11 | Hostile bytes parsed in the core, and the sandbox-to-host result channel | Medium | A page, or a compromised sandbox | Length-prefixed closed-schema frame, fail closed, no page bytes on error | planned |
| 18 | K16 | Intelligence integrity: lures, cloaked or poisoned pages | Medium | An operator who wants to mislead | Provenance in every result, no automated action | planned |
| 19 | K07b | Log and stored data read by a local same-user process | Medium | Same-user code execution | Modes, no bodies, retention; partly accepted | planned |
| 20 | K13 | The tool is distinguishable or can be cloaked against | Medium | An operator who profiles visitors | Stock configuration, request discipline; accepted in part | inferred; manual |
| 21 | K14 | Network adversary: correlation, malicious relays, honeypots | Medium | Position at both ends or a controlled relay | Client-only, few small requests; accepted | not testable here |
| 22 | K15 | Resource exhaustion by a page or server | Low | A page or a slow server | Streaming byte cap, wall-clock cap, redirect cap | planned |

Counts: 22 risks, 22 mitigations, 22 verifications (sections below).

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

### K02a, K02b, K02c. Sandbox escape, split by tier and boundary crossed

Treat each tier's isolation as breakable. Different events have different impact and prerequisites, so each is its own
risk. A common verification principle applies to all three: the check is a **positive inventory taken from outside the
sandbox**. The sandbox is described by an explicit expected set (mounts, descriptors, devices, sockets, process
credentials, interfaces, routes, attachments), the host enumerates what actually exists, and anything not in the
expected set fails the check. A blacklist of known-bad settings is not accepted as evidence, and nothing reported from
inside the sandbox is trusted, because a breached sandbox can misreport.

Shared mitigations: no secret, token, repository, credential socket or host directory is placed where the sandbox could
reach it; a non-root sandbox user; ephemeral sessions (K12); engines kept current (K09).

#### K02a. T1: a browser compromise reaches the user account

- **Abuse case.** A page exploits the browser. The attacker runs code as the account that started it.
- **If it happens.** If that account is the maintainer's own, everything in A-2 is exposed, along with the allowlist
  and logs, and the real address is known. The browser and every other program share one trust boundary [W, Browsing
  Setups page]. This is the weakest tier by decision [D].
- **Impact.** Critical. **Prerequisite.** One browser exploit, delivered by any page. Light.
- **Mitigation.** Run T1 only under a dedicated OS account that has none of the maintainer's credentials, no access to
  the maintainer's home directory, agent sockets or session bus, no elevated rights, and its own runtime directory; the Tor client runs under a different identity from the browser (see K03);
  add process confinement where the platform offers it [I]. Document that T1 under the daily account is the same as no
  isolation.
- **Verification.** Planned, run from the host by the maintainer or an administrator account, not by the tool: enumerate
  the dedicated account's user and group ids, supplementary groups, environment, open descriptors, mounts and sockets it
  can reach, and the files under the maintainer's home it can read (expected: none); compare with a recorded expected set
  and fail on any addition. Planned test: the tool refuses to start T1 when the current account is not the configured
  dedicated one.
- **Residual.** Accepted by decision. Reopen if T1 is ever used under an account with credentials.

#### K02b. T2: worker breach, then container escape

- **Abuse case.** Stage one: a page compromises the browser or parser inside the worker. Stage two: a flaw in the
  container runtime or kernel is used to leave the container.
- **If stage one succeeds.** The attacker can use the local proxy ports (traffic leaves as Tor or I2P traffic, not as
  the maintainer's address), forge result text (K01) and attack the control channel (K06). It reaches no secret if none
  is mounted.
- **If stage two succeeds.** Code runs on the host as the runtime's user: the maintainer's own user if rootless, root for
  a root-run daemon. A breach of the daemon container instead reveals the real address.
- **Impact.** Critical. **Prerequisite.** A browser exploit and a second, runtime-level flaw. Heavy.
- **Mitigation.** Rootless runtime; capabilities dropped; no new privileges; read-only root filesystem; size-limited
  tmpfs; default syscall filter kept; no runtime or host sockets, devices or host directories; worker on an internal
  network (A1); the daemon container holds no secret and no write path to the worker's state.
- **Verification.** Planned, host-observed: for the running worker and daemon containers, read from the host the
  effective mounts, descriptors, namespaces, capability and no-new-privileges flags, syscall-filter mode, devices,
  interfaces and routes, **and every listening socket and every published port mapping** (from the kernel's
  per-process records and the runtime's own inspection output) and compare each with the recorded expected set; any
  extra item fails. The set is closed for listeners: each is an exact protocol, bind address, port, network namespace and
  owning process identity, and one additional listener, a wildcard bind, a host-published port or an alternate transport
  makes the check fail and startup refuse. The generated definition is also compared, but the running
  state is what counts.
- **Residual.** An unpatched runtime or kernel flaw defeats this. Reopen on any published escape for the runtime in use.

#### K02c. T3: Workstation, Gateway and hypervisor crossings

- **Abuse case.** Three distinct crossings. (1) The Workstation is compromised. (2) The Gateway is compromised. (3) A
  hypervisor flaw lets a guest reach the host.
- **If (1).** By Whonix's design the attacker still does not learn the real address [W, project claim, untested by the
  wiki author]; it can forge results and attack the control channel.
- **If (2).** The real address is exposed.
- **If (3).** The host and everything on it. A compromised host compromises every VM [W, Whonix Warning page].
- **Impact.** Critical. **Prerequisite.** A browser exploit, then a VM-boundary or Gateway flaw. Heavy.
- **Mitigation.** Domain definitions generated by the wrapper from a positive template, not editable from the guest; no
  shared folders, clipboard or display channel the verb set does not need, no device or USB passthrough; the Workstation
  attached only to the internal network with the Gateway; the guest agent speaks only the verb protocol; the host choice
  and credentials in K10.
- **Verification.** Planned, host-observed: for the running domains, the effective definition (dumped from the
  hypervisor after start, not the template), the hypervisor process's descriptors and arguments, and the bridge
  attachments are compared with the expected set; the Workstation has exactly one interface, on the internal network,
  and the only other member of that network is the Gateway; the Gateway's external interface is the only one with a
  route out. The three separations (Workstation to Gateway, Gateway to host, guest to host) are tested independently,
  each with its own expected set.
- **Residual.** A hypervisor flaw defeats this. Virtualization enlarges the trusted computing base [W]. Reopen on any
  published escape for the hypervisor in use.

### K03. Real IP or identity leak

- **Abuse case.** A page triggers a request that does not use the anonymity network; a name is resolved outside the
  proxy; a program or browser component in the sandbox ignores proxy settings or runs in another network context; a
  client bug exposes the address; a mis-wired network gives the worker, the daemon container or the Workstation an
  unintended route. The Tor Project says Tor protects only applications configured to use it, and that other programs
  can reveal the non-Tor address [W, Browsing Setups page].
- **Impact.** High: A-1.
- **Prerequisites.** A page that causes a request (any page); a bug or a wiring mistake.
- **Mitigation.** Name resolution is done by the proxy (SOCKS with remote resolution) and never locally. The fetch path
  opens no other process: no external viewers, plugins or document handlers. Non-text content types are refused (K15).
  Each tier states its network invariant and the invariant is checked where it is enforced, not inside the guest:
  - **T1.** When the browser and its Tor client run as one account, no host-side rule can tell them apart. A rule that
    lets the Tor client reach its relays also lets a compromised browser reach those relays directly, from the real
    address, and destination counters cannot show which process originated the traffic. T1 therefore **cannot make the
    claim** that the browser has no route except through Tor unless the host enforces a separation it can observe: the
    Tor client and the browser run under distinct enforcement identities (separate accounts, or separate network
    namespaces or control groups), only the Tor identity may own sockets to the outside, and the browser identity can
    reach only a local proxy endpoint. If that separation is not set up, T1 is documented as unable to claim the
    invariant, and the leak-by-browser-flaw case for T1 is accepted residual risk.
  - **T2.** The worker's network namespace has one interface, on the internal network, with routes only to the daemons'
    proxy ports and no resolver; the daemon container is the only workload with outside egress, and its egress excludes
    the host, the local network and link-local ranges.
  - **T3.** The Workstation is attached only to the internal network with the Gateway; the Gateway's firewall passes
    Tor traffic only (Whonix's design claim [W]); the host's own network is not used by the Workstation.
- **Accepted exposure, recorded, not mitigated by route isolation.** An i2pd router (T1 with a host-side router, T2)
  connects to I2P peers directly, so the host's address is visible to them [W, How I2P Works page; the tier consequence
  is I]. The alternative the Whonix project documents as preferred is I2P through Tor inside the Workstation, with its
  own cost: no stream isolation, community support only [V]. The design must pick one, and the maintainer accepts the
  result. i2pd is configured not to publish itself or relay transit traffic where its configuration allows [I; verify
  against the i2pd documentation].
- **Verification.** Planned, at the enforcement point and outside the guest: (a) T1: from the browser's actual process
  identity (not the Tor client's), attempt direct TCP, UDP, DNS, IPv6 and ICMP to a destination that the Tor identity
  is permitted to reach and to arbitrary destinations; every direct attempt must fail while traffic through the local
  proxy succeeds. A capture that shows only permitted relay destinations does not pass this check, because it cannot
  show who originated them; the check fails if the browser identity can reach a permitted relay directly. (b) T2: from the host, enter the worker's namespace and list interfaces and routes
  (expected: one interface, proxy routes only); from the host firewall and connection-tracking view, confirm the daemon
  container's egress and that the worker has none. (c) T3: the bridge and Gateway firewall views described in K02c.
  Negative tests for every interface and destination class (loopback, local network, link-local, the metadata range,
  IPv6, ICMP, DNS on both transports): each fails closed. Effective DNS handling: the recording proxy shows host names it
  resolved remotely and no resolver query leaves anywhere else. Subprocess coverage: the T1 and T2 checks run while a
  stub page forces subresource and helper-process activity.
- **Residual.** T1: any browser flaw can leak unless the separate-identity arrangement above is in place and observed. All tiers: the local network sees Tor or I2P use [W]. Direct I2P peer
  visibility is accepted exposure unless the I2P-through-Tor path is chosen.

### K04. Allowlist matching bypass, redirect, unbrokered requests, or widening by persuasion

- **Abuse case.** (a) A look-alike destination passes the match: a different host with the same visible prefix, user
  information in the URL, a trailing dot, case or encoding variants, an unexpected port or scheme. (b) An allowlisted page
  redirects to a destination that is not on the list, or to the ordinary internet. (c) A page, or the injected AI,
  persuades the maintainer to add a destination. (d) An allowlisted page causes requests the user never asked for:
  images, stylesheets, frames, scripts, fonts, refresh directives, prefetching, or requests made by browser helper
  processes. Each may name a destination that is not on the list. Checking redirects does not cover them.
- **Impact.** High: it removes default deny, which every other control assumes.
- **Prerequisites.** (a) and (b): a page and a parser difference. (c): a plausible message. (d): an allowlisted page.
- **Mitigation.** Parse once into a canonical host, port and scheme, held as an **immutable canonical destination
  object**; the broker authorizes that object, and **dispatch consumes only that object, never the original input
  string**. Nothing downstream parses the string again, so no second parser can read it differently. The redirect check,
  the probe capability (second capability below) and the proxy request are all built from the same object, and
  encodings and normalization (case, percent-encoding, trailing dots, Unicode forms, default ports, user information)
  are resolved once, before authorization. Match exactly against canonical entries; reject
  anything the parser cannot canonicalize. Allow only the schemes the networks need. Redirects are not followed
  automatically; each hop is re-checked against the allowlist and counted against a small cap; a redirect to a
  non-allowlisted or non-network destination is refused. The tool has no verb that edits the allowlist, and promotion of a
  discovered destination is a human act made outside any tool the AI can call (D7). The denial message gives no hint
  about how to widen the list.
  **Broker invariant.** Every network request, of every class (navigation, redirect, subresource, prefetch, refresh,
  helper-process request, and discovery probe), passes through one policy-enforcing request path that authorizes it
  **before** dispatch by checking one of exactly two capabilities, never by a special case:
  (1) a **fetch** requires the destination to match the private allowlist; (2) a **one-hop probe** requires a
  single-use capability issued by the host-side controller for a candidate that is a canonical link extracted from the
  current response of an allowlisted fetch, bound to that parent and to the run identifier. The probe capability permits
  only the bounded liveness, title and category probe (K08); it cannot extract links, cannot be used to fetch, cannot
  become a seed, is consumed by its one use, and expires when the run ends. A stored lead, a sibling lead that was not
  issued a capability, a lead from an earlier run, and an arbitrary destination hold no capability and are denied. Default
  deny is unchanged: nothing is dispatched without one of the two. Request classes that cannot be brokered are disabled: the sandbox loads
  no subresources, runs no script, and does no prefetch or speculative connection, and the fetch returns the document
  text only. Where a tier cannot enforce this (T1 drives a full browser, so brokering depends on browser configuration
  that a compromised browser can bypass), the model does not claim it: T1 is recorded as unable to guarantee the
  invariant against a compromised browser, and for T2 and T3 the enforcement point is the proxy the sandbox must use.
- **Verification.** Planned **authorization-to-dispatch test**, end to end: for each destination form in the table
  (including ambiguous encodings and normalization differences between components), compare three tuples for equality:
  the `(scheme, host, port)` the broker authorized, the tuple in the redirect or probe capability, and the tuple the
  **proxy observes leaving**, recorded at the egress point and not in the guest. Any mismatch fails; so does any second
  parse of the original string (a test hook makes the dispatch path fail if it receives anything other than the
  canonical object) and any request observed at the proxy for which no authorization record exists. Planned test: a
  table of hostile destination forms, each denied, and of valid forms, each passed; a
  redirect-to-forbidden test and a redirect-loop test; a test that no tool verb writes the allowlist path. Planned
  **request-class fixture**: an allowlisted document that tries each request class (image, stylesheet, frame, script,
  font, refresh, prefetch, helper-process request) toward a forbidden destination; assert zero broker dispatches and
  zero proxy or network observations for that destination, observed at the proxy, not in the guest. Planned
  **probe-capability tests**: the allowlisted-fetch candidate B is probed exactly once; a second probe of B, an arbitrary
  destination, a stored lead, a sibling lead without a capability, a lead from an earlier run, and a probe used as a
  fetch each fail with zero network observation.
- **Residual.** Judgment of the maintainer on (c). T1 cannot guarantee (d) against a compromised browser. Reopen if the
  allowlist format gains wildcards, or if any request class is ever enabled.

### K04b. Allowlist file substitution and same-user tampering

This is separate from K04. K04 is about what the matcher accepts; K04b is about whether the file the matcher reads is
the file the maintainer meant.

- **Abuse case.** (a) The configured path is a symbolic link at any position, or sits under a directory someone else can
  change, or points at an unintended regular file. (b) The path or any of its components is replaced during resolution,
  so the open reaches a different tree than the one checked. (c) A process running as the same user rewrites the file.
- **Impact.** High: the allowlist decides what the tool may touch.
- **Prerequisites.** (a) and (b): the ability to write the path or a parent. (c): code execution as the user, which a T1
  breach (K02a) gives.
- **Mitigation, against (a) and (b).** The path comes from the tool's own configuration and is absolute. Resolution is
  **constrained and symlink-free at every component, atomically or descriptor by descriptor**: either one kernel call
  that forbids symbolic links and magic links and keeps resolution beneath the starting directory (for example
  `openat2` with the no-symlink and beneath constraints [I; verify against the kernel documentation for the platforms
  supported]), or a walk that opens each component relative to the descriptor of the previous one, refusing symbolic
  links, and checks each opened directory with `fstat` (owned by the user or root, no group or world write) before
  descending. A platform with neither is unsupported for this tool. The final file is opened relative to the verified
  parent descriptor, and the checks run on the opened descriptor (regular file, owned by the user, not group- or
  world-writable, link count one). The content is read once from that descriptor, held in memory, and its digest is
  logged; the file is not reopened per call, and a reload repeats the whole procedure. The tool refuses a path inside a
  repository.
- **Against (c): accepted, not mitigated.** A process with the maintainer's own authority can replace the file, and can
  also edit the tool's configuration and the log, so a logged digest shows a change only if the log was out of its reach.
  No outside-authority anchor is specified in the design. Therefore **same-user tampering is recorded as accepted
  residual risk**, and nothing above is claimed to prevent it. If the maintainer wants it closed, the option is a
  signature on the allowlist verified against a public key held by a different authority (a hardware key, or off the
  machine), in the manner of SAFO's signed approvals [I]. That is a design decision for #7.
- **Verification.** Planned tests in a scratch directory: a symbolic link in **every** path position (each parent
  directory and the final component) is refused; a parent replaced by a link, or swapped for another tree, during
  resolution makes the load fail (using a test hook that pauses between steps); a file with a link count above one is
  refused; a group-writable file and a group-writable parent are refused; a file in a git work tree is refused; a file
  replaced after the open does not change the allowlist held in memory; a changed file changes the logged digest on
  reload. `namei -m <allowlist path>` is a human diagnostic of the modes along the path; it shows nothing about which
  objects a later open traverses and is not offered as proof.
- **Residual.** Same-user tampering, accepted (above). Reopen if an anchor outside the user's authority is specified.

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
- **Mitigation.** The closed verb registry (D5, "Verb registry"), each verb with a schema; the argument and exposure tests are generated from the registry, so `probe`, `status`, `revert` and `fetch` are all covered; the screenshot verb is operator-only and absent from the AI-facing tool, so a test enumerates the tool's verbs and fails if it appears; arguments are validated, then passed as an argument
  vector, never assembled into a shell string; values that begin like an option are rejected; names such as snapshots
  and domains come from configuration, not from the caller; length limits; the guest side accepts only schema-valid
  messages and answers with bounded text; the host treats everything from the guest as untrusted (A2).
- **Verification.** Test (planned): hostile-argument fixtures (option-like, whitespace and newline, shell metacharacters,
  path traversal, oversize, wrong type) against every verb in the registry (the test enumerates the registry and fails if a verb has no fixtures), expected to be rejected before any process is started, using
  a stub that fails the test if a process is spawned. Test (planned): a guest-message fuzz against the host parser.
- **Residual.** Parser bugs remain possible; keep the channel small and review it first.

### K07. The log and stored data leave the machine

- **Abuse case.** The request log or the discovery store is copied by a backup or synchronization job to a remote
  store, committed to a repository, pasted into an issue, or returned into the consuming AI's transcript. It lists the
  maintainer's research history and, in Phase 2, service identifiers (A-5, A-6). Much of this has no recognizable
  address syntax, so an address pattern check does not see it.
- **Impact.** High. The same disclosure through the repository is K17, High; the route does not change the consequence.
- **Prerequisites.** A sync or backup job whose scope includes the directory, or one mistaken command; or, through the
  consuming AI, text on any fetched page that induces a request for the log (K01), which is why no such verb exists.
- **Mitigation.** The state directory is outside any repository and outside every directory a synchronization or backup
  tool covers; the tool resolves its effective paths at startup, prints them on request, and refuses a path inside a
  git work tree. The log has an exact, enumerated schema (D4): timestamp, network, normalized destination, allowlist
  digest, status, byte count, truncation flag, error class; no bodies, query strings, cookies or headers; unknown fields
  are rejected. Retention is bounded and enforced by the tool. **No AI-facing verb returns log entries,
  history or resolved paths.** Log inspection is operator-only, like the screenshot verb: it is absent from the AI-facing
  tool, because "only on request" is no boundary when the requester can be the injected AI (K01). If the AI needs a
  status operation, it returns only the status of the current request and aggregate health counters, with no historical
  destinations or times. An AI-facing read of discovery records (K08) is likewise limited to records created in the
  current run [I].
- **Verification.** Planned: (1) a command prints the resolved storage paths; the maintainer compares them with the
  exclusion lists of each sync and backup tool in use. (2) A test asserts the schema: every field enumerated, a line
  with an extra field fails. (3) A retention test with aged fixture entries confirms purge. (4) Modes: `stat -c '%a %U'`
  shows 600 for files and 700 for the directory. (5) A test that a state path inside a git work tree is refused. (6) A **verb-enumeration test** that fails if the
  AI-facing tool exposes any verb that returns log entries, history or storage paths, and a **hostile-consumer test**: a
  stub consumer, driven by injected text, tries every AI-facing verb and argument to obtain prior destinations, times or
  paths and must get none. The
  repository address check (`./scripts/check-addresses.sh`) is a K17 control only and is not offered as evidence here.
- **Residual.** The consuming AI's own transcript is outside Knight Rider's storage (F5). A new sync tool added later
  silently widens the scope; the signal to reopen is any change to backup or sync configuration.

### K07b. The log and stored data read by a local same-user process

- **Abuse case.** Another process or agent running as the maintainer reads the log or the store.
- **Impact.** Medium: the same content as K07, no publication.
- **Prerequisites.** Code execution as the user.
- **Mitigation.** Modes 0600 and 0700; no bodies or headers; bounded retention; an encrypted volume where available
  [I].
- **Verification.** Planned: the mode and schema checks above.
- **Residual.** Same-user read access cannot be prevented by file modes. Accepted, consistent with K04b.

### K08. Discovery lane: fan-out past one hop, and second-order injection

- **Abuse case.** (a) An allowlisted page yields a lead. An implementation stores more than the decision permits, or
  later treats a stored lead as a seed, and repeated expansion builds a multi-hop graph of services. Each fetch looks
  locally valid. (b) A page sets a title or other short field that the discovery lane records. Later the AI reads the
  store or the log, and the stored string carries instructions or forged structure; the hostile text has been
  laundered through the tool's own storage and looks like the tool's output. A log line can also be forged if page text
  can contain a newline.
- **Impact.** High: (a) breaks the Phase 2 scope decision and widens exposure to abusive content (K05); (b) has the effect
  of K01, delayed, and the maintainer trusts it more.
- **Prerequisites.** A page that contains a lead or sets a field; for (b), a later read of the store.
- **Mitigation.**
  - **Schema.** A discovery record holds exactly three fields: liveness, title and category. The earlier draft also
    listed the public source and a confidence note (issue #1 mentions them); they are removed here because the recorded
    decision (#2, #4) names three fields. Adding any field is a decision for the maintainer, not an implementation
    detail, and the schema test fails on an extra field.
  - **Persisted representation.** The check covers everything persisted, not only the response object. The store is one
    collection of leads whose **only key is the lead's canonical destination** (a record about a lead must name it; this
    is permitted explicitly and is distinct from the three-field payload) and whose payload is `liveness`, `title` and
    `category`. There is no other column, key or index (only the primary key on the destination), no parent identifier,
    no extraction time, no run identifier, no first or last seen value, no seed or eligibility flag, no side table, no
    sidecar or journal file beyond the storage engine's own, and no discovery fields in the request log beyond the K07
    log schema. The binding of a candidate to its parent fetch lives only in controller memory for the run and is never
    persisted.
  - **Probe isolation.** Every probe runs in its own fresh sandbox instance (K12: one network transaction per
    instance). Sibling candidates never share an instance, and no state carries from one probe to the next except the
    host-held, run-bound capabilities. A probe whose instance cannot be verified clean is refused, not run.
  - **One hop.** The only input to discovery is a link extracted, in the current run, from a fetch of a destination that
    matched the allowlist. A stored discovery record is never an eligible input: the discovery function accepts a parent
    only if it is allowlist-matched, and a record carries no state that makes it a seed. A probe runs only under the single-use,
    run-bound capability described in K04, which the controller issues for candidates from the current response of an
    allowlisted fetch; a liveness or title probe of a lead does not extract links from the probed page. Rate and size caps apply to probes (gate #4).
  - **Second order.** Fields are normalized, length-capped and stripped of control characters at write time; the log
    format escapes newlines and delimiters; every read path that returns stored strings to the AI uses the K01 envelope
    and says the fields are untrusted; counts and categories are computed by code [I].
- **Verification.** Planned tests, with the network stubbed: (00) a **sibling-candidate test**: A yields B and D; B plants state or poisons the result channel; D must run in a distinct verified-clean instance (or be refused) and see none of B's state; the same test is mirrored in K12. (0) a **full-store dump test**: dump the entire backing store (schema introspection including every table, column and index, every file in the state directory, the engine's journal and write-ahead files, and the log) and compare it with the declared representation above; any undeclared column, key, index, auxiliary record, file or seed state fails. (1) a **graph fixture**: allowlisted page A links to B, and
  B links to C. The test asserts exactly one request to B, zero requests to C, and no record for C. (2) A schema test:
  a stored record has exactly the three fields; an extra field fails. (3) A test that a stored record cannot be passed
  to the discovery entry point. (4) A title containing a newline, a fake log line, a fake envelope and control characters
  is stored; the log still parses as one line per event and a read returns the title escaped inside the envelope.
- **Residual.** Plain-language instructions in a title again pass (F1). Gate #4 is not written, so discovery must not
  run until it is.

### K09. Supply chain: browser, daemons, images, dependencies

- **Abuse case.** A tampered or outdated Tor Browser, Tor, i2pd, Whonix image, container base image or build dependency
  is installed; a mutable tag is repointed; or an old one is left in place and a published flaw is used against it.
- **Impact.** High: it runs inside the sandbox and, through K02, beyond it.
- **Prerequisites.** A compromised upstream or download path, or neglect.
- **Mitigation.** Two separate controls, because they prove different things.
  - **Pinning policy, parse-and-fail.** A script parses every artifact reference in the repository (image
    definitions, image and VM references, browser download manifests, dependency locks) and fails unless **each one**
    meets the policy: referenced by digest, or by version plus an expected digest recorded in a pin file. A tag-only,
    floating or unparseable reference fails. Finding a digest elsewhere in the same file does not count.
  - **Provenance verification, separate.** For each pinned artifact: the signature verifies against the vendor's
    published key whose fingerprint is recorded in the pin file; the downloaded content matches the recorded digest;
    build provenance is checked where the vendor publishes it [I]; and the pin's recorded date is not older than a
    maximum age, after which the check fails until the pin is reviewed. Procedures are written down with the date and
    verified against each vendor's page at the time [I].
  - **Binding the pins to what runs.** Pins that exist on paper prove nothing about the bytes executed. At **every
    start**, before any sandbox is created, the controller resolves each **effective** artifact from the runtime
    configuration (not from the repository): the container image actually selected, the browser executable actually
    launched, the daemon binaries, the VM disk and snapshot actually attached, and the dependencies actually loaded. For
    each it computes or reads the content digest and identity (running image digest, executable hash, snapshot or disk
    identity) and compares them with the approved pin manifest. It **refuses to start** on a missing, mutable (tag-only
    or floating), unverifiable or mismatched artifact. The comparison is repeated against the running instance
    (the image digest the runtime reports for the running container, the hash of the launched executable) after
    creation and before the first fetch, so a configuration that selects one artifact and a runtime that runs another
    also fails closed.
  - Vulnerability scanning (the GYST `security` workflow, Dependabot) stays, as a separate signal. It is not evidence of
    provenance.
- **Verification.** Planned: `./scripts/check-pins.sh` exits 0 on the real tree. Test: a fixture with one digest-pinned
  and one tag-only reference must exit non-zero. Test: an expired pin fails; a digest mismatch fails; a signature that
  does not match the recorded fingerprint fails (using stubs, no network). **Run-time binding test:** pin artifact A
  and configure artifact B (a different image digest, an older local VM disk, a different executable); startup must
  fail **before sandbox creation**, with no instance created. A second case selects A in configuration but makes the
  runtime run B; the post-creation comparison must refuse the first fetch. Each artifact class (image, browser
  executable, daemon binary, VM disk or snapshot, dependency) has its own case.
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
- **Verification.** Checklist the maintainer signs off before first run: which credentials exist on the host and which
  account runs the VMs. **Enforcement-level negative tests, using the actual credential the wrapper holds** (not the
  wrapper's own checks): attempt, against the hypervisor, an operation on an unconfigured domain, on a network, on a
  storage pool, on a secret, and a host-level action; each must be **denied by the hypervisor**. Then compare the
  credential's effective permissions with a closed expected set, which is exactly the hypervisor operations in the Verb
  registry on the named domains; **startup refuses if the effective permissions are broader**, and the check fails if
  the controller can issue any hypervisor operation outside that set. Test (planned): the wrapper also refuses any
  domain name not in its configuration, as a second layer.
- **Residual.** Virtualization enlarges the trusted computing base [W, Whonix threat-model page, quoted by the wiki].
  This one is the maintainer's decision, not a code fix.

### K11. Hostile bytes parsed in the core, and the sandbox-to-host result channel

- **Abuse case.** (a) A response is crafted to break the HTML, charset, compression or text-extraction code: deep
  nesting, huge inputs, decompression bombs, encodings that disagree, malformed headers. (b) A **compromised sandbox**
  sends the host a hostile result: an oversized or unterminated frame, a length that disagrees with the data, duplicate
  or unknown or mistyped fields, trailing or repeated frames, invalid text encoding, or partial output after a crash.
- **Impact.** Medium: a parser bug in the host process would sit outside the sandbox, and a malformed result is a route
  to the AI (K01) or to host memory.
- **Prerequisites.** (a) A page or a server response. (b) A compromised sandbox (K02).
- **Mitigation.** Parse and sanitize inside the sandbox (A2); use a memory-safe language and a maintained parser; limit
  nesting, total size and decompression ratio; refuse unknown encodings. For the **result channel**, the host owns the
  contract and fails closed:
  - **Framing.** One length-prefixed frame per fetch. The host reads the fixed-size length first, rejects any length
    above the enforced maximum **before allocating or reading the body**, and reads exactly that many bytes with a
    deadline. Any byte after the frame, a second frame, a short read, or a timeout rejects the result.
  - **Schema.** The guest-to-host frames are exactly the variants below, one per (verb, outcome) combination, and
    nothing else is accepted. The tables are normative: the implementation's schema and its tests are generated from
    them. For every variant, the fields listed as required are all present and each appears once; **every field not
    listed for that variant is forbidden**, and there are no optional fields anywhere. There is no free-form
    diagnostic, note or error-text field, because any such field would carry page-derived bytes across the channel.
    Unknown, duplicate, missing, forbidden or wrongly typed fields fail.

    Field types and bounds:

    | Field | Type | Bound |
    |---|---|---|
    | `v` | unsigned integer | exactly 1 |
    | `verb` | enumeration | must equal the host's pending request; one of the guest-facing verbs in the registry |
    | `outcome` | enumeration | per variant below |
    | `text` | UTF-8 string | at most the configured output cap, in bytes |
    | `text_len` | unsigned integer | at most the cap |
    | `guest_truncated` | boolean | |
    | `liveness` | enumeration | `up`, `down`, `timeout` |
    | `title` | UTF-8 string | at most 200 bytes after normalization |
    | `category` | enumeration | the closed list the host defines; any other value fails |

    Variants (R = required, all others forbidden):

    | Verb | Outcome (or liveness) | Required fields |
    |---|---|---|
    | `fetch` | `outcome = ok` | `v`, `verb`, `outcome`, `text`, `text_len`, `guest_truncated` |
    | `fetch` | `outcome = refused_type` | `v`, `verb`, `outcome` |
    | `fetch` | `outcome = failed` | `v`, `verb`, `outcome` |
    | `probe` | `liveness = up` | `v`, `verb`, `liveness`, `title`, `category` |
    | `probe` | `liveness = down` | `v`, `verb`, `liveness` |
    | `probe` | `liveness = timeout` | `v`, `verb`, `liveness` |
    | `revert` | `outcome = ok` | `v`, `verb`, `outcome` |
    | `revert` | `outcome = failed` | `v`, `verb`, `outcome` |

    So a failed or refused fetch carries no text, length or truncation flag, and a probe that is down or timed out
    carries no title or category. **Length checks:** the frame's length prefix is authoritative for how many bytes the
    host reads and is checked against the total encoded frame length; `text_len` is checked only against the UTF-8 byte
    length of `text`, never against the frame. **Host-owned, never read from the guest:** destination, network, time,
    the response byte count (observed at the proxy), the redirect hop count, the error class and its text, the allowlist
    digest, and the request identifier. Truncation by the **host** (the output cap) is a host observation;
    `guest_truncated` is a separate guest assertion and the two are never merged. The operator-only `screenshot` verb
    returns an opaque image to a private operator directory and is not part of the AI-facing channel.
  - **No page-derived output on error.** Any sanitizer failure, crash, timeout, truncation ambiguity or encoding error
    returns a fixed, host-generated error that contains no byte derived from the page (not even a partial title), and
    marks the sandbox poisoned (K12).
- **Verification.** Planned **schema-generated test**: from the normative table, generate for every (verb, outcome) variant a
  positive case, one case per required field absent, duplicated, mistyped and out-of-bound, one case per **forbidden**
  field present (for example `text` on a failed fetch, or a title on a probe that is down), and one case that adds an
  extra field with a plausible name (for example a diagnostic or note field); the implementation must reject all of them and must fail the
  test suite if it accepts any field the table does not list. Planned tests from a **hostile guest stub**, each
  expected to be rejected with the fixed error and no page-derived bytes: a length above the maximum (the test also checks the host did not allocate near that size); a
  length that disagrees with the data; an unterminated frame; trailing bytes; two frames; a duplicate field; an unknown
  field; a missing field; a mistyped field; invalid UTF-8; a crash or timeout after partial output. Planned property and
  fuzz tests for the in-sandbox parser with a time and memory budget; a bomb fixture that must stop at the cap.
- **Residual.** A sandbox-contained parser bug still lets the attacker forge a well-formed result (K01). The schema
  makes the result checkable, not true.

### K12. Ephemerality fails: state survives a run or links runs

- **Abuse case.** A cookie, cache entry, service worker, profile file, daemon state, changed configuration or a
  surviving process outlives a use of the sandbox; a cleanup silently fails and the next fetch starts contaminated; a
  compromised guest lies to whatever inspects it; circuits are reused so two fetches are linked.
- **Impact.** Medium: it ties visits together and lets an earlier breach persist.
- **Prerequisites.** A prior hostile page, or a cleanup error, or a compromised guest.
- **Mitigation.**
  - **Lifecycle.** The unit is **one network transaction per sandbox instance**: exactly one `fetch` **or** exactly one `probe`,
    never several (a multi-transaction session is a different, named mode, with weaker isolation, and is not
    modeled). Each probe of a discovery operation gets its own fresh or reverted, host-verified instance; the run-bound
    probe capabilities (K04) are held only in host-controlled memory across those instances. Create or revert from the
    recorded clean image; the host verifies it; exactly one transaction
    runs; teardown; the instance is destroyed or reverted. A failure at any transition, or any error from the result
    channel (K11), leaves the instance **poisoned**: no fetch runs on it, and only a verified new instance clears the
    state. "Run," "fetch" and "session" in this model mean this one unit.
  - **Evidence the host controls.** Each attested property names its source, and a property that has no independent
    source is not attested:
    - Image or snapshot identity: the host's own record of what it created or reverted (host-controlled).
    - Fresh start: the identifiers the host assigned when it created the instance (host-controlled).
    - Writable storage: for a container or VM, the host inspects the instance's backing storage from outside the
      guest, offline or from a fresh snapshot comparison, against the recorded clean state (host-controlled). Where the
      tier does not support that, this property is **not independently observable** and is stated as a residual.
    - Process list and profile identifier: **not independently observable for a VM** without a guest agent, and a
      guest agent is a guest-derived claim. They are not attested for T3 from guest data; T3 relies on destroying and
      recreating the guest from the clean image instead. For T2 the host reads the process table of the container from
      outside (host-controlled).
    - Network-isolation token: set and held by the host-side proxy or Gateway configuration (host-controlled).
  - Cleanup after the fetch is defense in depth. Known I2P linkability in the Whonix path (no stream isolation [V]) is
    outside the guarantee.
- **Verification.** Planned **sibling-candidate test**: an allowlisted page yields candidates B and D; the probe of B plants
  state (a profile change, cache entry, background process, writable file) or poisons the result channel; the probe of D
  must run in a distinct, verified-clean instance, or be refused until one exists, and must observe none of B's state.
  Planned tests against the **real backend** for T2 and T3 (stubs alone are insufficient here):
  state planted outside any inventory the guest reports (on a second writable volume, in a daemon directory, in the
  guest's disk, in a background process) must make the host-side check fail and the next fetch refused; a failure
  injected at every lifecycle transition (create, verify, fetch, teardown, revert) must leave the instance poisoned and
  every following fetch blocked until a verified new instance exists. On a stubbed backend, the same transitions test
  the wrapper's state machine.
- **Residual.** I2P linkability through Tor stays [V]. Properties marked not independently observable (guest process
  list and profile identifier in a VM, and writable-storage inspection on any tier that cannot offer it) rest on
  destroy-and-recreate and are not attested; a flaw in the hypervisor or the host-side inspection (K02) defeats the
  rest.

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

### K18. The private allowlist leaves the machine through its own sync

- **Abuse case.** The allowlist is deliberately kept in a private synced configuration store, so that the same file
  reaches the other machines that run the tool, including a remote box. That intended crossing (TB10) is itself a
  disclosure path. The sync account or its remote copy is compromised; sharing or visibility is misconfigured (the store
  is made public, a collaborator or token is added, a copy is shared by mistake); older copies persist in history,
  backups, recovery copies, caches or other machines' checkouts; the remote box's copy is readable by another account or
  swept into that box's own backups; or an entry reaches a log, pull request, issue, agent transcript or error message
  because something printed it. The allowlist reveals substantially the same research targets as the request log (A-4,
  A-5).
- **Impact.** High: the same as K07, and a copy that has left cannot be recalled.
- **Prerequisites.** Compromise or misconfiguration of the sync channel or of any one copy; or, for the paste route, an
  agent or script that prints the file. The first needs a credential or a mistake; the second needs only a careless
  step, which is why it is ranked with K07.
- **Mitigation.** (Everything here is [I] except where a project statement is cited; the maintainer's synced store and
  machines are described only in generic terms.)
  - **Where the file lives.** One canonical private path, outside every checkout of this repository and outside the
    tool's state directory. The repository carries only the placeholder example (D3).
  - **What syncs it.** Only the private synced configuration store, which must be private, access-limited, protected by
    strong authentication, and shared with the minimum set of accounts and machines. Nothing else (no second backup
    tool, no cloud folder, no shared drive) covers the path. Optionally the file is encrypted before it enters the
    store, with the key held outside the store, so a copy of the store alone does not disclose it.
  - **Who can read each copy.** Each machine's copy is mode 0600 in a 0700 directory, owned by the account that runs the
    tool and no other. On the remote box, the read path is that account only; the box's own backups either exclude the
    path or are private and encrypted; the box has no other user with access to that account's files.
  - **No contents elsewhere.** The tool never prints an allowlist entry in a log, error, status or result (the log
    carries only the allowlist digest, K07); denials name no entry; agents are told to use the digest and never to read,
    quote or paste the file; no pull request, issue, commit message or test fixture contains a real entry (K17).
  - **Trusted and accepted.** The sync provider and the security of the maintainer's account with it are trusted;
    history and recovery copies that already exist are treated as permanent, so the remedy for a suspected disclosure is
    to retire the affected entries, not to expect deletion.
- **Verification.** Planned: (1) an **operational readiness check**, run by the maintainer before the tool is enabled
  on a machine and after any change to sync configuration, that inventories the effective remote destinations and the
  sharing state of the configured sync mechanism (visibility, collaborators, tokens, machines) read-only, compares them
  with a recorded **approved private scope**, and **fails** if the allowlist is synced anywhere outside it. (2) On each
  machine: the mode and owner of the file and directory (`stat -c '%a %U'` shows 600 and 700 for the account that runs
  the tool) and the list of other backup or sync tools that cover the path (expected: none). (3) A **sentinel test**:
  the test allowlist contains a distinctive placeholder entry; the test runs every verb, error path and failure mode and
  searches every output, log, status response and test artifact for the sentinel; any hit fails. (4) A check on the
  repository that no tracked file or fixture holds a real entry (the address check is a K17 control and does not cover
  this).
- **Residual.** Trust in the sync provider and the maintainer's account; copies in history and recovery that already
  exist; physical access to any machine holding a copy. Reopen on any change to the sync mechanism or the set of
  machines, and on any suspected exposure of the store.

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
| T1 shares the account (K02a) | The maintainer, already decided as weakest [D] | T1 is used on an account with credentials |
| Trust in the private synced configuration store and the maintainer's account with it; existing history and recovery copies (K18) | The maintainer | The sync mechanism or the set of machines changes, or the store is suspected exposed |
| Same-user tampering with the allowlist, log and configuration (K04b, K07b); no outside-authority anchor is specified | The maintainer | An anchor outside the user's authority is specified, or an agent with shell runs as the same user |
| Direct I2P peer visibility of the host's address when i2pd runs on the host or in T2 (K03) | The maintainer | The design chooses I2P through Tor, or the host is shared |
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

- Security claims are repeated in the narrative and in the Threat Dragon file (flow and threat text). A planned check
  compares **structured claims**, not phrases: a claims manifest (the verb registry by caller, the per-variant result
  schema, the lifecycle steps, the broker capabilities, the persisted discovery representation, the pin-binding
  invariant) from which the narrative tables and the file's flow and threat text are checked, field by field. (For
  example the lifecycle in K12, the broker capabilities in K04, the closed
  result schema in K11, the verb registry, and the persisted discovery representation in K08) and fails if the narrative and the file disagree on them. The GYST checker validates the
  file's shape and topics, not that the two documents say the same thing.

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
