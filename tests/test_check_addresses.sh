#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Hermetic test for scripts/check-addresses.sh. Address-shaped strings are built at run time so this file
# holds none; everything happens in a temp directory; nothing touches a network.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/../scripts/check-addresses.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail=0

# gen LEN: LEN characters of a mixed base32 alphabet, so the result is not a one-character placeholder.
gen() {
    local alphabet=abcdefghijklmnopqrstuvwxyz234567 out="" i
    for ((i = 0; i < $1; i++)); do
        out+="${alphabet:$((i % 32)):1}"
    done
    printf '%s' "$out"
}
# rep CHAR LEN: CHAR repeated LEN times.
rep() {
    local out="" i
    for ((i = 0; i < $2; i++)); do
        out+="$1"
    done
    printf '%s' "$out"
}

expect() { # name want-exit file
    local name=$1 want=$2 file=$3 got=0
    "$check" "$file" >/dev/null 2>&1 || got=$?
    if [ "$got" -ne "$want" ]; then
        echo "FAIL $name: want exit $want, got $got" >&2
        fail=1
    else
        echo "ok   $name"
    fi
}

printf 'plain prose, a version v1.26.0 and a 40-char sha %s\n' "$(rep a 40)" >"$work/clean.txt"
expect clean-file 0 "$work/clean.txt"

printf 'see %s.onion for more\n' "$(gen 56)" >"$work/onion.txt"
expect v3-onion 1 "$work/onion.txt"

printf 'host %s.b32.i2p here\n' "$(gen 52)" >"$work/b32.txt"
expect b32-i2p 1 "$work/b32.txt"

printf 'dest=%s\n' "$(gen 520 | tr 'a-z2-7' 'A-Za-z~-' | head -c 520)" >"$work/dest.txt"
expect long-destination 1 "$work/dest.txt"

printf 'allowed %s.onion and %s.b32.i2p\n' "$(rep a 56)" "$(rep a 52)" >"$work/placeholder.txt"
expect placeholder-forms 0 "$work/placeholder.txt"

printf 'short %s.onion is not v3 shaped\n' "$(gen 16)" >"$work/short.txt"
expect short-onion-not-v3 0 "$work/short.txt"

printf '\0\001 binary %s.onion\n' "$(gen 56)" >"$work/binary.bin"
expect binary-skipped 0 "$work/binary.bin"

# The tracked example allowlist must stay clean.
expect example-allowlist 0 "$here/../examples/allowlist.example.yaml"

exit "$fail"
