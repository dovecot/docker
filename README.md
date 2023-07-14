Dovecot CE docker image source files
====================================

This repository contains Dockerfile and assets for images that are published to https://hub.docker.com/u/dovecot.

License
-------

The source code for these docker images is licensed under Attribution-NonCommercial-ShareAlike 4.0 International, but you are welcome to use the images hosted at docker.com for commercial purposes.

Instructions
------------

This image comes with default configuration which accepts any user with password pass. To customize the image, mount /etc/dovecot and /srv/mail volumes.
Listeners

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
