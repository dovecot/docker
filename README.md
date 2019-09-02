Instructions
============

This repository contains images that are published to https://hub.docker.com/u/dovecot.

Logins
------

To push into docker hub you need an docker hub account linked to Dovecot organization.
Ask from Aki Tuomi / Timo Sirainen for access.

Once you have access, you can use `docker login` to enable pushing to this repository.

Making new image
----------------

Copy existing directory, update version(s) and run

```.sh
docker build -t dovecot/dovecot:<version>
docker tag dovecot/dovecot:<version> dovecot/dovecot:latest
docker push dovecot/dovecot:version
docker push dovecot/dovecot:latest
```
