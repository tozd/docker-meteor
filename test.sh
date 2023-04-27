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

exit 0