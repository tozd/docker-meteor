# tozd/meteor

<https://gitlab.com/tozd/docker/meteor>

Available as:

- [`tozd/meteor`](https://hub.docker.com/r/tozd/meteor)
- [`registry.gitlab.com/tozd/docker/meteor`](https://gitlab.com/tozd/docker/meteor/container_registry)

## Image inheritance

[`tozd/base`](https://gitlab.com/tozd/docker/base) ← [`tozd/runit`](https://gitlab.com/tozd/docker/runit) ← `tozd/meteor`

See also [`tozd/meteor-testing`](https://gitlab.com/tozd/docker/meteor-testing).

## Tags

- `ubuntu-xenial-*`: Meteor versions using Ubuntu 16.04 LTS (Xenial) as base
- `ubuntu-bionic-*`: Meteor versions using Ubuntu 18.04 LTS (Bionic) as base
- `ubuntu-focal-*`: Meteor versions using Ubuntu 20.04 LTS (Focal) as base
- `ubuntu-jammy-*`: Meteor versions using Ubuntu 22.04 LTS (Jammy) as base

Some versions are not build because [they have issues](./blocklist.txt).

## Volumes

- `/var/log/meteor`: Log files.

## Variables

- `ROOT_URL`: Used by Meteor to construct [absolute URLs](http://docs.meteor.com/#/full/meteor_absoluteurl).
  It should not contain a trailing `/`. Example: `http://example.com`.
- `MAIL_URL`: Used to configure [e-mail server](http://docs.meteor.com/#/full/email).
  Example: `smtp://user:password@mailhost:port/`.
- `METEOR_SETTINGS`: JSON string of your [Meteor settings](http://docs.meteor.com/#/full/meteor_settings).
- `MONGO_URL`: MongoDB database URL. Example: `mongodb://mongodb/meteor`.
- `MONGO_OPLOG_URL`: MongoDB database oplog URL. Example: `mongodb://mongodb/local`.
- `LOG_TO_STDOUT`: If set to `1` output logs to stdout (retrievable using `docker logs`) instead of log volumes.

## Ports

- `3000/tcp`: HTTP port on which Meteor app listens.

## Description

Image which can serve as a base Docker image for dockerizing [Meteor](https://www.meteor.com/) applications.

In the root directory of your Meteor application (the one with `.meteor` directory) create a `Dockerfile` file
with the following content:

```
FROM registry.gitlab.com/tozd/docker/meteor:ubuntu-focal-<Meteor version>
```

For example:

```
FROM registry.gitlab.com/tozd/docker/meteor:ubuntu-focal-1.10.2
```

Meteor version should be the version of Meteor you want to use to build your Meteor application.
By using a fixed version of Meteor you achieve reproducible builds of your application.
You can also specify the Ubuntu LTS version you want to use as the basis of your Docker image.
In the example above, this is Ubuntu Focal.
See all available tags on [Docker Hub](https://hub.docker.com/repository/docker/tozd/meteor/tags).

And your Meteor application is dockerized. To optimize image building, especially if you are building the image from a directory where you are also developing the application, add `.dockerignore` file with something like:

```
.meteor/local
packages/*/.build*
node_modules
```

The intended use of this image is that it is run alongside the
[tozd/meteor-mongodb](https://gitlab.com/tozd/docker/meteor-mongodb) image for MongoDB database for your Meteor
application. You will probably want a HTTP reverse proxy in front. You can use [tozd/docker-nginx-proxy](https://gitlab.com/tozd/docker/nginx-proxy) image which provides [nginx](https://nginx.org/) configured as a reverse proxy with automatic SSL support provided by [Let's encrypt](https://letsencrypt.org/).

When running Docker image with your Meteor application, you should configure at least `ROOT_URL`, `MONGO_URL`, and `MONGO_OPLOG_URL` environment variables.

You can specify those environment variables when running an image, but you can also export them from the script
file volume mounted under `/etc/service/meteor/run.config`.

Example of a `run.config` file:

```bash
MONGODB_ADMIN_PWD='<pass>'
MONGODB_CREATE_PWD='<pass>'
MONGODB_OPLOGGER_PWD='<pass>'

export MONGO_URL="mongodb://meteor:${MONGODB_CREATE_PWD}@mongodb/meteor"
export MONGO_OPLOG_URL="mongodb://oplogger:${MONGODB_OPLOGGER_PWD}@mongodb/local?authSource=admin"
```

Only `export` lines are necessary for this image, but others are used by `tozd/meteor-mongodb` image.
You can export also other environment variables.

When you are extending this image, you can add a script `/etc/service/meteor/run.initialization`
which will be run at a container startup, after the container is initialized, but before the
Meteor application is run.

If you have to do anything to the base Docker image, before your Meteor application starts building (e.g., installing
an Ubuntu package), add a `docker-source.sh` file to the root of your Meteor application and it will be run
before the build.

## Testing image

For testing Meteor applications, use [`tozd/meteor-testing`](https://gitlab.com/tozd/docker/meteor-testing) Docker image instead.

## GitHub mirror

There is also a [read-only GitHub mirror available](https://github.com/tozd/docker-meteor),
if you need to fork the project there.
