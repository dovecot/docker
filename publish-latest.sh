#!/usr/bin/env bash

set -eu

VERSION=${VERSION:-2.4.1}

##
# latest
for stage in "-root" "-dev" ""; do
	docker manifest rm dovecot/dovecot:latest-2.4$stage || true
	docker manifest rm dovecot/dovecot:latest$stage || true
	docker manifest create dovecot/dovecot:latest-2.4$stage \
		--amend dovecot/dovecot:$VERSION$stage-amd64 \
		--amend dovecot/dovecot:$VERSION$stage-arm64
	docker manifest push dovecot/dovecot:latest-2.4$stage
	docker manifest create dovecot/dovecot:latest$stage \
                --amend dovecot/dovecot:$VERSION$stage-amd64 \
                --amend dovecot/dovecot:$VERSION$stage-arm64
	docker manifest push dovecot/dovecot:latest$stage
done
