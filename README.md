Image which can serve as a base Docker image for dockerizing [Meteor](meteor.com) applications.

In the root directory of your Meteor application (the one with `.meteor` directory) create a `Dockerfile` file
with the following content:

```
FROM tozd/meteor:ubuntu-bionic
```

And your Meteor application is dockerized. To optimize image building, especially if you are building the image from a directory where you are also developing the application, add `.dockerignore` file with something like:

```
.meteor/local
packages/*/.build*
node_modules
```

The intended use of this image is that it is run alongside the
[tozd/meteor-mongodb](https://github.com/tozd/docker-meteor-mongodb) image for MongoDB database for your Meteor
application. You will probably want a HTTP reverse proxy in front. You can use [tozd/docker-nginx-proxy](https://github.com/tozd/docker-nginx-proxy) image which provides [nginx](https://nginx.org/) configured as a reverse proxy with automatic SSL support provided by [Let's encrypt](https://letsencrypt.org/).

When running Docker image with your Meteor application, you have to configure the following environment variables:

* `ROOT_URL` – used by Meteor to construct [absolute URLs](http://docs.meteor.com/#/full/meteor_absoluteurl), it
  should not contain a trailing `/`; example: `http://example.com`
* `MAIL_URL` – used to configure [e-mail server](http://docs.meteor.com/#/full/email);
  example: `smtp://user:password@mailhost:port/`
* `METEOR_SETTINGS` – JSON string of your [Meteor settings](http://docs.meteor.com/#/full/meteor_settings)
* `MONGO_URL` – MongoDB database URL; example: `mongodb://mongodb/meteor`
* `MONGO_OPLOG_URL` – MongoDB database oplog URL; example: `mongodb://mongodb/local`
* `LOG_TO_STDOUT` – if set to `1` log output to stdout instead to `/var/log/meteor`

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
