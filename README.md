Dovecot CE docker image source files
====================================

This repository contains Dockerfile and assets for images that are published to https://hub.docker.com/u/dovecot.

License
-------

The source code for these docker images is licensed under Attribution-NonCommercial-ShareAlike 4.0 International, but you are welcome to use the images hosted at docker.com for commercial purposes.

Instructions for 2.4
---------------------

This image comes with default configuration which accepts any user with password `password`. To persist data, mount `/srv/mail` volumes.
You can also mount extra configuration to override the default settings to `/etc/dovecot/conf.d`.

TLS certificates go to `/etc/dovecot/ssl`, and by default full-chain certificate filename is `tls.crt` and private key file is `tls.key`.

To run read-only, remember to mount tmpfs to `/tmp` and `/run`, and persistent data storage to `/srv/vmail`.

If you want to run without any extra linux capabilities, set `chroot=` to services `imap-login`, `pop3-login`, `submission-login` and `managesieve-login`.

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

Help
----

Note that these images come with absolutely no warranty or support. For questions and feedback send email to dovecot@dovecot.org.
