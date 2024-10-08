#!/bin/bash

set -eu

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    '--help')   set -- "$@" '-h'   ;;
    '--dovecot-version') set -- "$@" '-d'   ;;
    '--pigeonhole-version')   set -- "$@" '-p'   ;;
    '--dovecot-repo-url')     set -- "$@" '-r'   ;;
    '--image-name')     set -- "$@" '-i' ;;
    '--image-tag')     set -- "$@" '-t' ;;
    *)          set -- "$@" "$arg" ;;
  esac
done


function print_usage()
{
  echo "Usage: $0 [options...] <build-target>"
  echo ""
  echo " build-target: directory where Dockerfile of the target build is located"
  echo " Options:"
  echo " --help"
  echo "    this help message"
  echo " --dovecot-repo-url <URL>"
  echo "    repository URL used to clone source codes for dovecot core and pigeonhole"
  echo " --dovecot-version <version>"
  echo "    dovecot version, must have a branch on the remote git repository"
  echo " --pigeonhole-version <version>"
  echo "    pigeonhole version, must have a branch on the remote git repository"
  echo " --image-name <name>"
  echo "    Name of the final built image"
  echo " --image-tag <tag>"
  echo "    Tag for the final built image"
}


IMAGE_NAME="dovecot-ce"
DOVECOT_VERSION=""
IMAGE_TAG=""
BUILD_ARGS=()
OPTIND=1
while getopts "hd:p:r:i:t:" OPT; do
  case $OPT in
  h)
    print_usage; exit 0 ;;
  d)
    DOVECOT_VERSION=$OPTARG; BUILD_ARGS+=(--build-arg DOVECOT_VERSION=$OPTARG) ;;
  p)
    BUILD_ARGS+=(--build-arg PIGEONHOLE_VERSION=$OPTARG) ;;
  r)
    BUILD_ARGS+=(--build-arg DOVECOT_REPO_URL=$OPTARG) ;;
  i)
    IMAGE_NAME=$OPTARG ;;
  t)
    IMAGE_TAG=$OPTARG ;;
  *)
    print_usage >&2; exit 1;;
  esac
done
shift $(expr $OPTIND - 1)

if [ -z "$DOVECOT_VERSION" ]; then
  echo "Error: Dovecot version must be provided" >&2
  print_usage >&2
  exit 1
fi

if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=$DOVECOT_VERSION
fi

DOCKER_BUILDKIT=1
docker help buildx &> /dev/null || DOCKER_BUILDKIT=0
export DOCKER_BUILDKIT
docker build ${BUILD_ARGS[@]} -t $IMAGE_NAME:$IMAGE_TAG $@
