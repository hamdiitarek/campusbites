#!/bin/sh
# Starts the Firebase emulators for project demo-campusbites and seeds them.
# Ctrl+C stops everything. The Firestore emulator needs Java 11+.
set -e
cd "$(dirname "$0")"
[ -d node_modules ] || npm install --no-audit --no-fund

firebase emulators:start --project demo-campusbites &
EMULATORS=$!
trap 'kill $EMULATORS 2>/dev/null' INT TERM EXIT

printf 'Waiting for the emulators'
until curl -s -o /dev/null http://127.0.0.1:8080 && curl -s -o /dev/null http://127.0.0.1:9199 && curl -s -o /dev/null http://127.0.0.1:9099; do
  printf '.'; sleep 1
done
echo
node seed.mjs
echo "Emulator UI: http://127.0.0.1:4000"
wait $EMULATORS
