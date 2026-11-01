#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Fails when a file holds a string shaped like a Tor v3 onion address, an I2P .b32.i2p address, or a long
# base64 I2P destination. This repository never contains real addresses. The one exception is an explicit
# placeholder: an address whose body is a single repeated character (the reserved example form), for
# example fifty-six letter a followed by .onion.
#
# Usage: scripts/check-addresses.sh [file ...]
# With no arguments it checks every tracked file. Exit 0 clean, 1 an address-shaped string was found,
# 2 usage or tooling error. A match is printed truncated, never in full.
set -euo pipefail

onion_re='[a-z2-7]{56}\.onion'
b32_re='[a-z2-7]{52}\.b32\.i2p'
dest_re='[A-Za-z0-9~+/-]{400,}'
# A body that is one character repeated is a placeholder, whatever its length.
placeholder_re='^([A-Za-z0-9~+/-])\1+(\.|$)'

files=()
if [ "$#" -gt 0 ]; then
    files=("$@")
else
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(git ls-files -z)
fi

status=0
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    for kind in onion b32 dest; do
        case "$kind" in
            onion) re=$onion_re ;;
            b32) re=$b32_re ;;
            dest) re=$dest_re ;;
        esac
        # -I skips binary files; grep exits 1 on no match, which is the clean case.
        while IFS=: read -r line match; do
            if printf '%s\n' "$match" | grep -Eq "$placeholder_re"; then
                continue
            fi
            printf '%s:%s: %s-shaped string (%.6s...)\n' "$f" "$line" "$kind" "$match" >&2
            status=1
        done < <(grep -EnoI -- "$re" "$f" || true)
    done
done

if [ "$status" -ne 0 ]; then
    echo "check-addresses: address-shaped string found; use a placeholder (one repeated character)" >&2
fi
exit "$status"
