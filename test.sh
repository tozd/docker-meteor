#!/bin/sh

set -e

version() {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

cleanup_docker=0
cleanup_mongo=0
cleanup_app=0
cleanup_image=0
cleanup_config=0
cleanup() {
  set +e

  if [ "$cleanup_docker" -ne 0 ]; then
    echo "Logs"
    docker logs test

    echo "Stopping Docker image"
    docker stop test
    docker rm -f test
  fi

  if [ "$cleanup_mongo" -ne 0 ]; then
    echo "Logs MongoDB"
    docker logs mongotest

    echo "Stopping MongoDB"
    docker stop mongotest
    docker rm -f mongotest
  fi

  if [ "$cleanup_app" -ne 0 ]; then
    echo "Removing test app"
    rm -rf test
  fi

  if [ "$cleanup_image" -ne 0 ]; then
    echo "Removing Docker image"
    docker image rm -f testimage
  fi

  if [ "$cleanup_config" -ne 0 ]; then
    rm -f run.config
  fi
}

trap cleanup EXIT

METEOR_VERSION="${TAG##*-}"

installed_version="$(docker run --rm --entrypoint '' "${CI_REGISTRY_IMAGE}:${TAG}" meteor --version | tail -n 1)"
if [ "$installed_version" != "Meteor ${METEOR_VERSION}" ]; then
  echo "Error: $installed_version is installed, wanted ${METEOR_VERSION}"
  exit 1
fi

echo "Preparing"
apk add --no-cache git

echo "Creating test app"
git clone https://github.com/meteor/clock test
cleanup_app=1

if [ "$METEOR_VERSION" = "1.0.2" ]; then
  target="1.0.1"
elif [ "$METEOR_VERSION" = "1.1.0.1" ]; then
  target="1.1"
else
  target="$METEOR_VERSION"
fi

# Find a commit of the app which is closest to the version we want. We really
# want to start at 0.9.2, the earliest version we support, but there is
# messy history (conflicts) so we start around 0.9.0.1 instead.
found=0
for commit in $(git -C test rev-list HEAD ^03d3b986dfc355901eae9a2740375d5fd14e7f6f) ; do
  git -C test checkout --quiet "$commit"
  release="$(cat test/.meteor/release)"
  if [ "$release" = "METEOR@$target" ]; then
    found=1
    break
  fi
done
if [ $found -eq 0 ]; then
  # We could not find the exact version, so we go with the latest one and update it to the version we are testing.
  echo "Updating test app"
  git -C test checkout --quiet master
  echo "{}" > "test/package.json"
  time docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor update --release "$METEOR_VERSION"
  if docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor npm version > /dev/null ; then
    if [ "$(version $METEOR_VERSION)" -ge "$(version "1.8.2")" ]; then
      time docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor npm install --save @babel/runtime
    elif [ "$(version $METEOR_VERSION)" -ge "$(version "1.6.1")" ]; then
      time docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor npm install --save @babel/runtime@7.0.0-beta.55
    elif [ "$(version $METEOR_VERSION)" -ge "$(version "1.4.2.1")" ]; then
      time docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor npm install --save babel-runtime
    fi
  fi
elif [ "$target" != "$METEOR_VERSION" ]; then
  # We could not find the exact version, so we use an older version and update it to the version we are testing.
  echo "Updating test app"
  time docker run --rm --entrypoint '' --volume "$(pwd)/test:/app" --workdir /app --env NODE_TLS_REJECT_UNAUTHORIZED=0 "${CI_REGISTRY_IMAGE}:${TAG}" meteor update --release "$METEOR_VERSION"
fi

echo "Building Docker image"
echo "FROM ${CI_REGISTRY_IMAGE}:${TAG}" > test/Dockerfile
time docker build -t testimage -f test/Dockerfile --build-arg NODE_TLS_REJECT_UNAUTHORIZED=0 test
cleanup_image=1

echo "MONGODB_ADMIN_PWD='test'" > run.config
echo "MONGODB_CREATE_PWD='test'" >> run.config
echo "MONGODB_OPLOGGER_PWD='test'" >> run.config
echo 'export MONGO_URL="mongodb://meteor:${MONGODB_CREATE_PWD}@mongotest/meteor"' >> run.config
echo 'export MONGO_OPLOG_URL="mongodb://oplogger:${MONGODB_OPLOGGER_PWD}@mongotest/local?authSource=admin"' >> run.config
cleanup_config=1

echo "Running MongoDB"
docker run -d --name mongotest -e LOG_TO_STDOUT=1 -p 27017:27017 -v "$(pwd)/run.config:/etc/service/mongod/run.config" registry.gitlab.com/tozd/docker/meteor-mongodb:2.6
cleanup_mongo=1

echo "Running Docker image"
docker run -d --name test -e LOG_TO_STDOUT=1 -p 3000:3000 -v "$(pwd)/run.config:/etc/service/meteor/run.config" --link mongotest:mongotest testimage
cleanup_docker=1

# It is OK to sleep just for 10 seconds because Meteor Docker image knows how to wait for MongoDB to become ready.
echo "Sleeping"
sleep 10

echo "Testing"
wget -T 30 -q -O - http://docker:3000 | grep -q '<title>SVG Clock Demo</title>'
echo "Success"
