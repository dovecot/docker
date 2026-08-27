# Dovecot Chronos Flavor

This directory contains the Docker configuration for building a Dovecot container image extended with the [push-notification-plugin-chronos](https://github.com/dovecot/push-notification-plugin-chronos) plugin.

## Overview

The Chronos plugin delivers HTTP push notifications when a calendar invitation (`MessageNew` with iTIP data) arrives in a user's mailbox.

This flavor is designed to be built independently on top of the pre-built base Dovecot images produced by the root `Dockerfile`.

## Targets Provided

| Target | Base Image | Description |
| :--- | :--- | :--- |
| `chronos` *(default)* | `dovecot/dovecot:<version>` | Minimal rootless production container with unused tools stripped |
| `chronos-dev` | `dovecot/dovecot:<version>-dev` | Rootless container with standard shell and diagnostic utilities |
| `chronos-root` | `dovecot/dovecot:<version>-root` | Traditional root-managed container |

## Building the Flavor

### Prerequisites

Ensure the base images have been built locally or are accessible in your registry:
- `dovecot/dovecot:<version>-build`
- `dovecot/dovecot:<version>` (or `-dev` / `-root`)

### Quick Build (Default target)

```bash
docker build -t dovecot-chronos:latest \
  --build-arg BASE_TAG=2.4.1 \
  -f flavors/chronos/Dockerfile \
  flavors/chronos
```

### Multi-Architecture / Multi-Target Build

Run the helper build script (supports both interactive wizard mode and scripted flags):

```bash
# Interactive wizard mode
./flavors/chronos/build.sh

# Or scriptable CLI mode
./flavors/chronos/build.sh -v 2.4.1 -p amd64,arm64 -t all
```

You can also invoke the generic flavor builder directly:

```bash
./flavors/build.sh chronos -v 2.4.1 --build-base
```

## Configuration

The default configuration file is installed at `/etc/dovecot/conf.d/90-push-notification-chronos.conf`.

The `push_notification_driver` setting defaults to a generic localhost URL, so you will almost certainly need to change that value.

To customize at runtime, mount your own configuration into `/etc/dovecot/conf.d/` or `/etc/dovecot/vendor.d/`.
