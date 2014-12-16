FROM tozd/runit

COPY ./etc /etc

ONBUILD COPY . /source
ONBUILD RUN apt-get update -q -q && \
 apt-get --yes --force-yes install software-properties-common curl && \
 add-apt-repository ppa:chris-lea/node.js && \
 apt-get update -q -q && \
 apt-get --yes --force-yes install nodejs && \
 cp -a /source /build && \
 rm -rf /source && \
 curl https://install.meteor.com/ | sh && \
 cd /build && \
 meteor build . && \
 cd / && \
 tar xf /build/build.tar.gz && \
 rm -rf /build && \
 rm -rf /root/.meteor && \
 cd /bundle/programs/server && \
 npm install && \
 apt-get --yes --force-yes purge software-properties-common curl && \
 apt-get --yes --force-yes autoremove && \
 adduser --system --group meteor --home /bundle && \
 chown -R meteor:meteor /bundle

ENV ROOT_URL http://example.com
ENV MAIL_URL smtp://user:password@mailhost:port/
ENV METEOR_SETTINGS {}
ENV PORT 3000
ENV MONGO_URL mongodb://mongodb/meteor
ENV MONGO_OPLOG_URL mongodb://mongodb/local

