FROM registry.gitlab.com/tozd/docker/runit:ubuntu-jammy

EXPOSE 3000/tcp

ENV ROOT_URL http://example.com
ENV MAIL_URL smtp://user:password@mailhost:port/
ENV METEOR_SETTINGS {}
ENV PORT 3000
ENV MONGO_URL mongodb://mongodb/meteor
ENV MONGO_OPLOG_URL mongodb://mongodb/local
ENV HOME /
ENV LOG_TO_STDOUT 0
ENV METEOR_NO_RELEASE_CHECK 1
ENV METEOR_ALLOW_SUPERUSER true

ARG METEOR_VERSION

VOLUME /var/log/meteor

COPY ./etc/service/meteor /etc/service/meteor

# Keep this layer in sync with tozd/meteor-testing.
RUN apt-get update -q -q && \
  apt-get --yes --force-yes install curl python2 build-essential git && \
  curl https://install.meteor.com/?release=${METEOR_VERSION} | sed s/--progress-bar/-sL/g | sh && \
  installed_version="$(meteor --version | tail -n 1)" && echo "Installed $installed_version, wanted ${METEOR_VERSION}" && [ "$installed_version" = "Meteor ${METEOR_VERSION}" ] && \
  apt-get --yes --force-yes purge curl && \
  apt-get --yes --force-yes autoremove && \
  adduser --system --group meteor --home / && \
  export "NODE=$(find /.meteor/ -path '*bin/node' | grep '/.meteor/packages/meteor-tool/' | sort | head -n 1)" && \
  ln -sf ${NODE} /usr/local/bin/node && \
  ln -sf "$(dirname "$NODE")/npm" /usr/local/bin/npm && \
  echo "export NODE_PATH=\"$(dirname $(dirname "$NODE"))/lib/node_modules\"" >> /etc/service/meteor/run.env && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm

ONBUILD COPY . /source
ONBUILD RUN rm -rf /source/.meteor/local /source/node_modules && \
  if [ -x /source/docker-source.sh ]; then /source/docker-source.sh; fi && \
  cp -a /source /build && \
  rm -rf /source && \
  cd /build && \
  meteor list && \
  if [ -f package.json ]; then meteor npm install --production --unsafe-perm; fi && \
  meteor build --headless --directory / && \
  cd / && \
  rm -rf /build && \
  if [ -e /bundle/programs/server/package.json ]; then cd /bundle/programs/server; npm install --unsafe-perm; fi && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm
