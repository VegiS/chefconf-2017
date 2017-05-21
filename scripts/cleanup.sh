#!/usr/bin/env bash
set -e

# Get the parent directory of where this script is and change into our website
# directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$(cd -P "$( dirname "$SOURCE" )/.." && pwd)"
cd "$DIR"

for file in $(ls -d */); do
  rm -rf "${file}/results"
done
