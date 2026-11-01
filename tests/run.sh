#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The repository's own checks: the unit test for the address check, then the address check itself over
# every tracked file. CI runs this through bash-ci's test-command.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
./tests/test_check_addresses.sh
./scripts/check-addresses.sh
echo "all checks passed"
