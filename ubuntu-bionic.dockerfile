FROM tozd/runit:ubuntu-bionic

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

ARG METEOR_VERSION

VOLUME /var/log/meteor

COPY ./etc /etc

RUN apt-get update -q -q && \
 apt-get --yes --force-yes install curl python build-essential git && \
 export METEOR_ALLOW_SUPERUSER=true && \
 curl https://install.meteor.com/${METEOR_VERSION:+?release=${METEOR_VERSION}} | sed s/--progress-bar/-sL/g | sh && \
 apt-get --yes --force-yes purge curl && \
 apt-get --yes --force-yes autoremove && \
 adduser --system --group meteor --home / && \
 export "NODE=$(find /.meteor/ -path '*bin/node' | grep '/.meteor/packages/meteor-tool/' | sort | head -n 1)" && \
 ln -sf ${NODE} /usr/local/bin/node && \
 ln -sf "$(dirname "$NODE")/npm" /usr/local/bin/npm && \
 echo "export NODE_PATH=\"$(dirname $(dirname "$NODE"))/lib/node_modules\"" >> /etc/service/meteor/run.env && \
 apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache ~/.npm

ONBUILD COPY . /source
ONBUILD RUN export METEOR_ALLOW_SUPERUSER=true && \
 rm -rf /source/.meteor/local /source/node_modules && \
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
