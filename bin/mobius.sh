#!/bin/sh
set -eu

CDPATH= cd -- "$(dirname -- "$0")/.."
channel=edm
case "${1-}" in
  edm|pop|soundscape|rock) channel=$1; shift ;;
esac
exec /Applications/SuperCollider.app/Contents/MacOS/sclang -D "infinite/infinite-$channel.scd" "$@"
