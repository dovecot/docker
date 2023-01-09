#!/bin/bash
set -euo pipefail

fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Header.
cat <<-EOH
# This file is generated via https://github.com/dovecot/docker/blob/$(fileCommit "$self")/$self
Maintainers: Aki Tuomi <cmouse@cmouse.fi> (@cmouse), Timo Sirainen <sirainen@sirainen.fi> (@sirainen)
GitRepo: https://github.com/dovecot/docker.git

EOH

## FIXME: Add support for 2.3-latest when 2.4 is out
latest=", latest"

head=$(git log -1 --format='format:%H' HEAD)

# Versions
for ver in `ls -rdv 2.3* | head -2`; do 
  if [ -d $ver ]; then
   h=$(fileCommit $ver)
   if [ "$h" != "" ]; then
     cat <<-EOH
Tags: $ver$latest
Architectures: amd64
Directory: $ver
GitCommit: $head

EOH
    latest=
    fi
  fi
done
