Dovecot CE docker image source files
====================================

This repository contains Dockerfile and assets for images that are published to https://hub.docker.com/u/dovecot.

License
-------

The source code for these docker images is licensed under Attribution-NonCommercial-ShareAlike 4.0 International, but you are welcome to use the images hosted at docker.com for commercial purposes.

Instructions for 2.4
---------------------

This image comes with default configuration which accepts any user with password `password`. To persist data, mount `/srv/vmail` volumes.
You can also mount extra configuration to override the default settings to `/etc/dovecot/conf.d`.

TLS certificates go to `/etc/dovecot/ssl`, and by default full-chain certificate filename is `tls.crt` and private key file is `tls.key`.

To run read-only, remember to mount tmpfs to `/tmp` and `/run`, and persistent data storage to `/srv/vmail`.

If you want to run without any extra linux capabilities, set `chroot=` to services `imap-login`, `pop3-login`, `submission-login` and `managesieve-login`.

Overriding authentication
-------------------------

If you override `auth.conf` in the container, note that it also contains

```
import_environment {
  DOVEADM_PASSWORD = %{env:DOVEADM_PASSWORD | default}
  USER_PASSWORD = %{env:USER_PASSWORD | default('{CRYPT}*')}
}
```

If you rely on either of these variables, you need to ensure you carry it over.

Listeners
------------
- POP3 on 31110, TLS 31995 (needs config file to enable, disabled by default)
- IMAP on 31143, TLS 31993
- Submission on 31587
- LMTPS on 31024
- ManageSieve on 34190
- HTTP API on 8080
- Metrics on 9090

Instructions for v2.3
---------------------

This image comes with default configuration which accepts any user with password pass. To customize the image, mount /etc/dovecot and /srv/mail volumes.

Listeners
---------

 - POP3 on 110, TLS 995
 - IMAP on 143, TLS 993
 - Submission on 587
 - LMTP on 24
 - ManageSieve on 4190

To run these images, simply use `docker run dovecot/dovecot:version`.

From 2.3.20+ you can also mount /etc/dovecot/conf.d with configuration files, that are going to get read by Dovecot. You can use these to overwrite or add
settings. Files must end in .conf.

Container Flavors and Extensions
--------------------------------

The [`flavors/`](flavors/) directory contains modular extensions ("flavors") built on top of the base Dovecot container images. Flavors allow adding custom plugins, drivers, or specialized configurations without bloating the base image.

### Building Flavors

An abstract build tool [`flavors/build.sh`](flavors/build.sh) is provided to build flavors either interactively or via CLI scripts. It will automatically check for and build missing base images if needed, and automatically detects either `docker` or `podman` in your PATH.

**Interactive Wizard Mode:**

```bash
./flavors/build.sh
```

**CLI / Scripted Mode:**

```bash
# Build the Chronos push notification plugin flavor:
./flavors/build.sh chronos -v 2.4.1

# Build multi-platform with all variants (production, dev, root):
./flavors/build.sh chronos -v 2.4.1 -p amd64,arm64 -t all --build-base

# Explicitly select a container engine (podman / docker):
./flavors/build.sh chronos -e podman
# Or via environment variable:
CONTAINER_ENGINE=podman ./flavors/build.sh chronos
```

Alternatively, each flavor directory provides a convenient wrapper script:

```bash
./flavors/chronos/build.sh
```

### Adding New Flavors

To add a new flavor, create a new directory under `flavors/<flavor_name>/` containing:
- `Dockerfile`: Multi-stage Dockerfile that builds against `${BASE_IMAGE_PREFIX}${BASE_TAG}-build` and copies the compiled modules into runtime targets (`${FLAVOR}`, `${FLAVOR}-dev`, `${FLAVOR}-root`).
- `config/`: Any default configuration files to copy into `/etc/dovecot/conf.d/`.
- `build.sh`: A minimal wrapper that delegates to `exec "${SCRIPT_DIR}/../build.sh" --flavor <flavor_name> "$@"`.

Help
----

Note that these images come with absolutely no warranty or support. For questions and feedback send email to dovecot@dovecot.org.
