#!/usr/bin/env bash
#
# Helper script to build the Chronos flavor.
# Delegates all build logic to the generic flavor build runner.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/../build.sh" --flavor chronos "$@"
