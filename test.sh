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

docker run --name test --entrypoint '' "${CI_REGISTRY_IMAGE}:${TAG}" meteor create --example clock /tmp/test || exit 3
docker cp test:/tmp/test test || exit 4
docker stop test || exit 5

cd test
echo "FROM ${CI_REGISTRY_IMAGE}:${TAG}" > Dockerfile

echo "Building Docker image"
docker build -t testimage -f Dockerfile .

echo "Running Docker image"
docker run -d --name test --rm -p 3000:3000 testimage || exit 6

echo "Sleeping"
sleep 10

echo "Testing"
wget -q -O - http://docker:3000 | grep -q '<title>SVG Clock Demo</title>'
result=$?

echo "Stopping Docker image"
docker stop test || exit 7

exit "$result"
