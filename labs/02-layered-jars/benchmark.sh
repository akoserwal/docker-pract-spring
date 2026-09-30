#!/usr/bin/env bash
set -euo pipefail

[[ -f sample-app/pom.xml ]] || { echo 'Run this script from the repository root' >&2; exit 1; }

echo 'Building initial images...'
docker build -f labs/01-basic-dockerfile/Dockerfile.naive -t spring-naive:bench .
docker build -f labs/02-layered-jars/Dockerfile.layered -t spring-layered:bench .

# Add a temporary comment to trigger a real source change. Restore on exit.
source_file=sample-app/src/main/java/com/example/dockerprac/DockerPracApplication.java
backup_file="$(mktemp)"
cp "$source_file" "$backup_file"
restore_source() { cp "$backup_file" "$source_file"; rm -f "$backup_file"; }
trap restore_source EXIT
printf "\n// Temporary benchmark change.\n" >> "$source_file"

echo 'Rebuilding the naive image...'
time docker build -f labs/01-basic-dockerfile/Dockerfile.naive -t spring-naive:bench .
echo 'Rebuilding the layered image...'
time docker build -f labs/02-layered-jars/Dockerfile.layered -t spring-layered:bench .
echo 'Inspect the COPY steps above to compare cache reuse.'
