#!/usr/bin/env bash
# Full Onion build in the amd64 toolchain container, tagged with a local suffix.
# Usage: scripts/kelsin-build.sh <suffix>      e.g. kelsin-001
# Output: out/release/Onion-v<VERSION>-<suffix>.zip and out/build/
# Builds in a container-local copy because `sed -i` fails on the Docker
# bind mount under amd64 emulation on Apple Silicon.
set -euo pipefail
cd "$(dirname "$0")/.."

suffix="${1:?usage: $0 <suffix> (e.g. kelsin-001)}"
base=$(sed -n 's/^VERSION=//p' Makefile | head -1)
version="${base}-${suffix}"
image=aemiii91/miyoomini-toolchain:latest

git submodule update --init --recursive
docker pull --platform linux/amd64 "$image"
rm -rf out

docker run --rm --platform linux/amd64 -v "$PWD":/src "$image" bash -c "
  set -e
  source /root/.bashrc
  mkdir /root/w
  cd /src && tar --exclude=.git --exclude=./out -cf - . | tar -xf - -C /root/w
  cd /root/w && make VERSION_OVERRIDE='$version' release
  mkdir -p /src/out && cp -a /root/w/release /root/w/build /src/out/
"
echo "Built: $(ls out/release/*.zip)"
