#!/usr/bin/env bash

set -eu

VERSION=${VERSION:-2.4.1}

## create manifests
#
for stage in "-root" "-dev" ""; do
	docker push dovecot/dovecot:$VERSION$stage-amd64
	docker push dovecot/dovecot:$VERSION$stage-arm64
	docker manifest rm dovecot/dovecot:$VERSION$stage || true
        docker manifest create dovecot/dovecot:$VERSION$stage \
		--amend dovecot/dovecot:$VERSION$stage-amd64 \
		--amend dovecot/dovecot:$VERSION$stage-arm64
	docker manifest push dovecot/dovecot:$VERSION$stage
done
