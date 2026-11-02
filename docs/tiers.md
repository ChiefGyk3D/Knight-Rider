<!-- SPDX-License-Identifier: Apache-2.0 -->
# Isolation tiers: what each protects and what it does not

Companion to `docs/design.md` (issue #9, parent #1). Knight Rider has one interface and three backends, so you
can pick the isolation you are comfortable with. This page says, for each, what it protects, what it does not,
which networks it reaches, what it costs to set up, and who it fits.

Nothing here was run. Each external fact is marked `verified (read 2026-11-02)` (read on the named page that
day), `wiki` (stated on the maintainer's CAH wiki pages "The browsing setups compared" and "Tor, I2P and the
darknet without the myths", which in turn cite projects, read 2026-11-01 by that page's author), or
`inferred` (my reading or a design assumption). The wiki pages are the base; where this page adds to them it
says so.

Placeholders only: this repository has no real onion or I2P addresses.

## The short version

| | Tier 1: Tor Browser driven directly | Tier 2: container with Tor and i2pd | Tier 3: Whonix Gateway and Workstation |
|---|---|---|---|
| Status in Phase 1 | **Unavailable** until a verified fail-closed interceptor exists | Available (build first) | Available (build second) |
| Isolation | Weakest. Trust boundary is the whole computer. | Middle. The fetcher cannot reach Tor or i2pd at all; a two-part broker fetches only what the controller authorized. | Strongest against address leaks. Workstation reaches only the Gateway. The allowlist does **not** survive a Workstation compromise. |
| Tor onion services | Yes | Yes | Yes |
| I2P eepsites | Not by itself. Needs a separate I2P router, otherwise Tor-only. | Yes, through i2pd | Not in Phase 1. Possible only as an experimental, community-supported I2P-over-Tor setup. |
| Reads pages that need JavaScript | Only if JavaScript is turned on, which we do not do | No (no browser) | Not in Phase 1 (same fetcher as Tier 2) |
| Build order | Last, and only after its gate | First | Second |
| Setup cost | Low | Medium | High |
| Fits | Not offered yet | Most people: a good balance, and it covers both networks | Someone with a dedicated host who wants a hostile page kept off their real network address by design |

No tier is safe in the sense of "nothing can go wrong". The wiki's comparison matrix has no green column, not
even for the setup that costs the most. Choosing a tier is choosing which failure you accept.

## What none of the tiers protect against

These apply to all three, and the wiki lists them for every setup:

- **Text aimed at the model.** Sanitizing removes hidden characters and markup. It cannot make persuasive text
  harmless. Page text always comes back marked as untrusted data (`docs/design.md` section 4), and Claude
  must not act on it without you. This is a property of the interface, the same in every tier.
- **An observer of both ends.** The Tor Project: Tor "does not defend against such a threat model"
  (`wiki`, citing the Tor Project's page on attacks that remain, read 2026-11-01).
- **Your provider seeing that you use Tor.** A bridge can hide it (`wiki`, citing Tails' warnings page). For
  I2P, running it is usually not a secret; the design hides what you do (`wiki`, citing the I2P introduction).
- **Your own habits.** The core is read-only and never signs in, so the sign-in risk the wiki describes does
  not arise in the core design. It would in any future authenticated mode, which is out of scope.
- **Altered hardware or firmware.** No setup on the wiki's matrix claims to cover it.
- **A tiny, careful allowlist is still your list.** The tool visits only what you wrote. A listed site can
  still serve a hostile page.

## Tier 1: Tor Browser driven directly (unavailable in Phase 1)

**This tier ships disabled.** A security review of the design found that turning off scripts and images does
not stop every stylesheet, font, refresh, navigation, download or browser-generated request, and that no one
has verified a way to approve every browser request before it leaves. Until a **pinned browser version** and a
**fail-closed pre-request interceptor** are built and verified at the proxy boundary (not just by what the
browser shows), a page could cause an automatic off-list request to leave the browser. It also needs a
streaming transport gate in front of the browser so size and time limits hold before hostile bytes reach it
(`docs/design.md` section 10). Everything below describes the tier as it would be once those exist.

**What it is.** The stock Tor Browser, driven by an automation library, with JavaScript off and images off,
sending one exact page request at a time. The page source goes to a separate no-network sanitizer process
(`docs/design.md` section 10).

**Networks.** Tor onion services: yes. I2P: **no, not by itself.** Tor Browser does not speak to I2P. The
options are Tor-only (what Phase 1 ships) or a separate I2P router with a separate browser profile used only
for I2P. The Whonix project warns that pointing the browser's HTTP proxy at an I2P router "breaks onion
service connections" and "worsen[s] the browser fingerprint", so that profile must be used for I2P alone
(`verified (read 2026-11-02)`, Whonix wiki, I2P page; that warning is written for Whonix, and applying it to
this tier is `inferred`).

**How it is automated.** Selenium WebDriver through geckodriver, via the third-party library `tbselenium`
(`verified (read 2026-11-02)`, its GitHub README: "A Python library to automate Tor Browser with Selenium
WebDriver"; lists Tor Browser 14.5.5 stable and 14.5a6 alpha, geckodriver 0.31.0 recommended; Linux only;
Xvfb or `headless=True`, with "WebGL is not supported" in headless). **Whether the Tor Project documents or
supports this is unverified:** the Tor Browser support index read on 2026-11-02 (`support.torproject.org/
tor-browser/`) lists no automation page. That Tor Browser exposes Marionette to geckodriver is `inferred`. The
library's maintenance state is unknown (no release date on the page; its CI badge points at Travis).

**What it protects.** The Tor Browser features the wiki lists: a circuit per site in the address bar,
standardized window size and User-Agent, three security levels, and amnesic behavior like private tabs; and
it hides your address from the site (`wiki`, citing Tor Project pages). Turning scripts and images off and driving one page at a time would close a lot of fingerprinting surface and many tracker paths
(`inferred`), but that is defense in depth, not the enforcement; the interceptor is.

**What it does not protect.**

- The wiki's central point: the trust boundary is **the whole computer**. Tor Browser protects its own
  traffic; "Tor does not protect all of your computer's Internet traffic" (`wiki`, quoting the Tor Project).
  A browser bug, or a stray program, is one step from your real address. Whonix's own page argues the same
  from its side, and says that a leak is possible "due to Tor Browser Bundle software defects" while the
  Workstation design is unaffected (project claim, `wiki`, not tested by the wiki author).
- Malware on the computer is not covered (`wiki` matrix).
- The browser knows the real address, so a browser bug can reach it. A 2013 case is documented on the wiki's
  Tor page (`wiki`).
- Even with the gate, the browser parses hostile bytes on your computer, and there is no broker or sandbox
  between the browser and the network beyond the interceptor.
- Parsing of the page happens in the sanitizer child process on the same computer, not in a sandbox.
  Mitigation: no network namespace and resource limits (`inferred`); it is still the same machine.
- The automation library is third-party code that controls the browser.

**Cost.** Lowest: Tor Browser, Python, geckodriver, a display (or Xvfb). No extra hardware. Free.

**Fits.** Someone who wants the least setup and who accepts that the boundary is the whole machine. The wiki's
own advice for this setup applies: keep the system updated and do nothing outside the browser. Not for
someone whose threat model includes a hostile page reaching their real address, or who needs I2P.

## Tier 2: container with a Tor daemon and i2pd

**What it is.** Five containers on three networks (`docs/design.md` section 9): a **fetcher** on an internal
network with no route out, a **two-part request broker** (a protocol stack and an egress gate) between the fetcher and the proxies, and a **tor**
and an **i2pd** container that reach the internet through an egress network. The fetcher is an ordinary HTTP client, not a browser. It has a read-only
root, no capabilities, resource limits, and no mount of your repos, secrets or tokens.

**Networks.** Tor onion services: yes, through the Tor container. I2P eepsites: yes, through i2pd's HTTP
proxy, with the outproxy off so no clearnet leaves through I2P. Both are first-class: the allowlist, log and
sanitizer treat them the same. i2pd needs direct internet access for its own peering and reseeding; it is
**not** chained through Tor (`verified (read 2026-11-02)`: i2pd documents NTCP2 over TCP and SSU2 over UDP and a
UDP SOCKS5 proxy option for SSU2; `inferred`: Tor provides no UDP SOCKS proxy, from the tor(1) manual).

**What it protects.**

- **The allowlist survives a broken fetcher and a broken protocol stack, but not a broken egress gate.**
  The fetcher parses hostile bytes, so it is treated as breakable; it has no network path to Tor or i2pd.
  Everything it learns comes through a two-part **broker**: `broker-front` handles TLS, HTTP headers and
  decompression (it handles hostile bytes too, so it is also treated as breakable, and has no path to a
  proxy), and `broker-egress` is a small gate that accepts one single-use capability from the controller and
  connects only to that network, host and port, then relays bytes without parsing them (`docs/design.md`
  section 9). Phase 1 allowlist entries are plain `http` only: onion and
  I2P transports already encrypt and authenticate end to end, and terminating TLS in the exposed protocol stack
  would let a taken-over stack send other methods and requests. An entry that names `https` is rejected; TLS
  termination in a small trusted gate is a deferred, separately reviewed item. Path scoping is kept for `http`
  entries.
- The isolation settings are checked as they actually run, not just as written: tests read each container's
  effective capabilities, seccomp and LSM state, mounts and flags, namespaces, devices and limits from the host
  (`docs/design.md` 9.5). The request log stores keyed hashes (a key outside the repository, rotated with the
  log), never literal hosts, so a copied log cannot confirm a guessed destination (`docs/design.md` 8.1).
- The egress gate writes the whole proxy-level destination itself (the Tor connect request or the I2P request
  line) from the controller's capability and accepts nothing from the protocol stack upstream, so a taken-over
  stack cannot steer the proxy to another destination.
- The allowlist file is checked through a no-follow descriptor walk and a content digest on every request, so
  in-place edits show up. This does not protect against another process running as your own user: such a
  process is inside the trusted boundary (accepted residual risk).
- Every hostile boundary has bounded, incremental framing (status and header bytes, header count, message
  and reply sizes, the protocol stack's reply to the fetcher, which the fetcher checks itself, deadlines), and the container egress policy is an exhaustive allow-only-global-unicast rule
  for both address families that also blocks directly connected routes and infrastructure addresses
  (`docs/design.md` 9.2 and 9.4), with a test per address class.
- Tor and i2pd expose only one listener each to the broker, their peer transports are on the egress side only,
  and each container has its own filter for an exact set of flows, proved by tests that enumerate listening
  ports (`docs/design.md` 9.4 and 9.5).
- A fetcher that tries to reach the internet, your LAN or DNS directly cannot: `kr_internal` is
  `internal: true`, which Docker describes as "an externally isolated network" (`verified (read 2026-11-02)`,
  Docker Compose networks reference). A program that "ignores Tor", the wiki's second threat, has no route.
- No browser means no JavaScript, no rendering, no fingerprint surface, no plugin or add-on path (design,
  section 9.4).
- Hostile bytes are parsed inside the fetcher container, not on your host.
- A fresh working directory per request, per-request Tor circuit isolation, no cookies or cache kept.

**What it does not protect.**

- **Your real address is visible to I2P peers.** i2pd talks to the I2P network directly; the container does
  not hide your connection from your provider, and your provider can see that you run I2P. The I2P design hides
  what you do, not that you use I2P (`wiki`, citing the I2P introduction). If that matters, use Tier 3 for
  Tor and skip I2P.
- **Containers share the host kernel.** A container escape or a kernel bug reaches your host. A virtual
  machine's boundary is generally considered stronger, but the Whonix project states that virtualization too
  "enlarges the TCB significantly" and that VM escapes are possible (`wiki`, quoting Whonix). So this tier's
  boundary is the container runtime and the kernel (`inferred` for the comparison of the two; the Docker
  and Podman security documentation was not read).
- **Malware on the host** is not covered, as on every tier except those that run apart from the host.
- **A bug in `broker-egress`, a proxy, or the host defeats the allowlist.** `broker-egress` is deliberately
  tiny (a fixed SOCKS exchange and a byte relay, no TLS, no HTTP, no decompression) and is the component the
  Phase 1 security review must read first. Tor and i2pd are treated as untrusted network software.
- **A bug in `broker-front`** can alter the bytes the fetcher sees, which is why the fetcher's output stays
  untrusted.
- **A bug in the image or the proxy software** (Tor, i2pd, the fetcher). They are pinned by digest, which
  stops silent changes and does not make them bug-free.
- Pages that need JavaScript return little or nothing.

**Cost.** Medium: a container runtime (Docker or Podman, open question 1 in the design), a Compose file from
this repository, five images pinned by digest with hash-locked dependencies (startup refuses a mismatch), and host firewall rules for the egress network (`inferred`; install
and test them on a plan, not on a live firewall). No extra hardware. First I2P fetch may be slow while the
router builds tunnels (the design measures this in the first approved run).

**Fits.** Most people, and the build-first tier. It reaches both networks, runs without a second machine, and
gives you a real "no route out" guarantee for the fetcher that Tier 1 lacks. Choose Tier 3 if you want the
boundary to be a hypervisor and are willing to run a dedicated host.

## Tier 3: Whonix Gateway and Workstation under KVM

**What it is.** Two virtual machines from the Whonix project (one request at a time; a second request is told
to wait): a **Gateway** that runs Tor and a **Workstation**
that can reach only the Gateway. Under KVM/QEMU/libvirt. Every request runs on a fresh
disposable disk overlay over an immutable, measured golden image, destroyed afterward. You control it with a
**closed verb set** on the host, never a shell: reset to a fresh overlay, run one allowed fetch, tear down, take a screenshot (for you only; it is not given to Claude). The
fetch runs inside the Workstation through a service on a vsock channel, which is not a network connection
(`docs/design.md` section 11).

**Networks.** Tor onion services: yes. I2P: **not in Phase 1.** `verified (read 2026-11-02)`, Whonix wiki,
I2P page: Whonix does not install I2P; the preferred way is to run the I2P router inside the Workstation and
connect to Tor before I2P; running it on the Gateway "is considered experimental" and "untested by Whonix
developers"; the I2P developers do not support or recommend running I2P over Tor; the section "is only
supported by the community". The page lists no stream isolation for I2P (visits can be linked through the
same `X-I2P-Dest*` headers), slower speed, no contribution to the I2P network, and tunnels that may take over 10
minutes to stabilize. So an I2P option on this tier is a later, experimental flag, and only if you ask for it.

**What it protects.** From the Whonix project's own statements, which the wiki repeats and did not test:
"Only connections through Tor are permitted", "DNS leaks are impossible", and malware with root in the
Workstation "cannot discover the user's real IP address" (`wiki`, citing the Whonix overview, modified
2026-09-19). This addresses the wiki's second and third threats (an app that ignores Tor; a bug that exposes the
real address) in a way the browser-only model does not. Add to that the fresh overlays for both VMs (destroyed after every request), so what a hostile
page does inside the VMs does not persist, and the no-open-shell control wrapper.

**What it does not protect.**

- **The allowlist, once the Workstation is compromised. Stated plainly: on this tier the allowlist does not
  survive a Workstation compromise.** Whonix is wired so the Workstation reaches Tor through the Gateway on its
  own, so the code that fetches and parses is also in a position to send any request. The container tier puts a
  broker in between; this tier does not (`docs/design.md` 11.5; whether a Whonix broker is possible is
  unverified). What this tier still gives is the strongest guarantee here about your real address (the
  project's claim, untested), a Workstation started fresh from a measured golden image every request, a closed verb set with no shell, and
  parsing away from your host. If you want the allowlist enforced against a taken-over fetcher, pick Tier 2.
- **The Gateway is reset too, but the host is not.** Resetting the Workstation does not by itself reset the
  Gateway, and the Workstation can reach it. So the control wrapper powers off **both** VMs and destroys both
  overlays at the end of every request and on every failure path, before it lets go of its lock, and marks both dirty if it crashes (they are
  contained before it serves anything again). The images are rebuilt from the Whonix project's on a schedule,
  and the clean state is an immutable, host-measured golden disk chain; every request runs on a fresh disposable overlay that is destroyed afterward, and a changed golden chain refuses to start (`docs/design.md`
  11.1 and 11.6). Anything outside
  the two VMs' disks (host, hypervisor, libvirt) is not reset by this.
- **The host.** Whonix's Warning page, per the wiki: the platform's security "is itself reliant upon the
  security of the host"; a compromised host compromises every Whonix VM; virtualization "cannot absolutely
  prevent the compromise of hardware, nor detect advanced malware" and VM escapes are possible; a dedicated
  host is safer (`wiki`; Warning page modified 2026-05-15; I did not re-read it).
- **Virtualization enlarges the trusted base** ("significantly", per the Whonix threat-model page), and the
  most robust separation is separate physical computers (`wiki`).
- **Behavior and identity mixing**, writing style, file metadata: not touched by the design, and mostly
  not relevant to a read-only tool.
- **Host choices that weaken it.** The Whonix KVM page advises against 3D acceleration ("increases the attack
  surface") and warns that virtiofs carries "higher host compromise risk" (`verified (read 2026-11-02)`,
  Whonix KVM page, which says it "is only supported by the community"). This tool uses none of them.
- **Host as shared box.** From the maintainer's own notes in #2: if the always-on box that might host this
  also holds the maintainer's assistant login, a VM escape from the Workstation reaches that login. Either
  keep that box's credentials out of reach of the VM host, or use a separate hypervisor. The control wrapper
  never carries those credentials, but the host does.
- Pages that need JavaScript: not read in Phase 1 (same fetcher as Tier 2).

**Host options and the host-trust caveat.**

- **A local machine** (current plan): the simplest, and the weakest on host trust because the same machine
  is the daily one. Nothing is launched there without the maintainer's explicit go and a written plan (#2).
- **The always-on Ubuntu box** (quad-core Xeon, 32 GB, per #2): double duty. Mind the host-risk note above.
- **An on-demand VM on a Proxmox cluster** (planned): Proxmox has its own API and would be a separate driver.
  Whether libvirt can drive it is `unverified`; it is not claimed.
- Libvirt covers local and remote KVM hosts (`verified (read 2026-11-02)`: the virsh manual's `screenshot`
  command; the remote transport is a design choice, not a libvirt claim). The control wrapper
  takes the host as configuration, so nothing assumes the maintainer's layout.

**Cost.** Highest of the three. A host that can run two VMs under KVM, Whonix's qcow2 images (use the ones the
project provides, per its KVM page), an immutable golden image, a small guest service and a host wrapper, plus
upkeep: updating the Gateway, Workstation and host. The Whonix project says safety "is materially improved by
using a dedicated host operating system solely for Whonix VMs" (`wiki`).

**Fits.** Someone who wants the Workstation to be unable to leak a real address by design, accepts a
hypervisor boundary, and will maintain a host. Not the best choice if you need I2P, where Tier 2 is the
supported route.

## Choosing

1. **Need I2P?** Tier 2. Tier 1 reaches it only with extra setup; Tier 3 only experimentally.
2. **Want the hostile page kept off your real address by architecture, and willing to run a host?** Tier 3.
3. **Want the least setup and accept the whole computer as the boundary?** Tier 1.
4. **Not sure?** Tier 2.

## What is verified and what is not

Added after the security review of PR #11 (no new external facts were read for these changes): the broker,
the unavailable status of Tier 1, the one-request rule for Tier 3 and the plain statement about the
allowlist and Workstation compromise are design decisions, not sourced claims.

Verified today (2026-11-02): the Docker Compose descriptions of `internal` and the container options; the
i2pd and tor(1) option names and defaults quoted in `docs/design.md`; the virsh `screenshot` syntax and the libvirt vsock device; the Whonix I2P page content; the Whonix KVM page's warnings
(first 100,000 characters only); the tbselenium README; the absence of an automation page on the Tor Browser
support index.

From the wiki only (not re-read here): the Tor Project's, Whonix's, Tails', Qubes' and Brave's statements in
the matrix, as the wiki records them.

Inferred or unverified: whether the Tor Project supports automating Tor Browser; Podman behavior; that
containers are a weaker boundary than virtual machines (a common view, not read today); Tor Browser preference
names for turning off scripts, images and downloads; the Whonix Gateway address and the Workstation's Python;
whether the I2P project accepts a client-only router with transit off; any figure for setup time or speed.
`docs/design.md` section 16 lists these as open questions.

## Requests and sessions

Phase 1 has no resumable sessions. Each lookup is one self-contained request with its own fresh instance, wiped
when it returns, so there is no session id to guess, join or end (`docs/design.md` 4.3 and 8.2).

## Discovery

The discovery lane stays disabled. Its claim that a candidate came from the page cannot be proven by a
breakable fetcher, so it waits for a trusted extractor with its own review (`docs/design.md` section 12).
