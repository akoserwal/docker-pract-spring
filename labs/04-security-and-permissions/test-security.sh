#!/usr/bin/env bash
set -euo pipefail

image='spring-boot-hardened:1.0'
container="spring-sec-test-$$"
port="${LAB_PORT:-18080}"
cleanup() { docker rm -f "$container" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker build -f labs/04-security-and-permissions/Dockerfile.hardened -t "$image" .
uid="$(docker run --rm --entrypoint id "$image" -u)"
[[ "$uid" == 10001 ]] || { echo "Expected UID 10001, got $uid" >&2; exit 1; }
echo 'PASS: process runs as UID 10001'

docker run -d --name "$container" \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --cap-drop=ALL --security-opt=no-new-privileges:true \
  -p "127.0.0.1:${port}:8080" "$image" >/dev/null

if docker exec "$container" touch /app/malicious.txt >/dev/null 2>&1; then
  echo 'Root filesystem accepted a write' >&2
  exit 1
fi
echo 'PASS: root filesystem is read-only'

for attempt in {1..30}; do
  if curl --fail --silent --output /dev/null "http://127.0.0.1:${port}/actuator/health/readiness"; then
    echo 'PASS: Spring Boot readiness endpoint is healthy'
    exit 0
  fi
  sleep 2
done
docker logs "$container" >&2
echo 'Spring Boot did not become ready' >&2
exit 1
