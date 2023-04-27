#!/bin/sh

METEOR_VERSION="${TAG##*-}"

installed_version="$(docker run --rm --entrypoint '' "${CI_REGISTRY_IMAGE}:${TAG}" meteor --version | tail -n 1)"
if [ $? -ne 0 ]; then
  echo "Error: Getting Meteor version failed"
  exit 1
fi

if [ "$installed_version" != "Meteor ${METEOR_VERSION}" ]; then
  echo "Error: $installed_version is installed, wanted ${METEOR_VERSION}"
  exit 2
fi

echo "Preparing"
apk add --no-cache git || exit 3

echo "Creating test app"
git clone https://github.com/meteor/clock test || exit 4
# Checkout app at Meteor release 0.9.2, the earliest version we support.
git -C test checkout ed95003ef71c5e0b5dbfd4054af67608b3b7a412
cd test
echo "FROM ${CI_REGISTRY_IMAGE}:${TAG}" > Dockerfile
# We update to the version we are testing.
docker run --rm --entrypoint '' --volume "$(pwd):/app" --workdir /app "${CI_REGISTRY_IMAGE}:${TAG}" meteor --release "$METEOR_VERSION" update --all-packages || exit 5

echo "Building Docker image"
docker build -t testimage -f Dockerfile . || exit 6

echo "Running Docker image"
docker run -d --name test --rm -p 3000:3000 testimage || exit 7

echo "Sleeping"
sleep 10

echo "Testing"
wget -q -O - http://docker:3000 | grep -q '<title>SVG Clock Demo</title>'
result=$?

echo "Stopping Docker image"
docker stop test || exit 8

exit "$result"
