#!/usr/bin/env bash
set -euo pipefail

image='spring-boot-distroless:1.0'
container="spring-distroless-test-$$"
port="${LAB_PORT:-18080}"
cleanup() { docker rm -f "$container" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker build -f labs/05-distroless-hardened/Dockerfile.distroless -t "$image" .
docker run -d --name "$container" -p "127.0.0.1:${port}:8080" "$image" >/dev/null

ready=false
for attempt in {1..30}; do
  if curl --fail --silent --output /dev/null "http://127.0.0.1:${port}/actuator/health/readiness"; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  docker logs "$container" >&2
  echo 'Spring Boot did not become ready' >&2
  exit 1
fi
echo 'PASS: Spring Boot readiness endpoint is healthy'

if docker exec "$container" /bin/sh -c true >/dev/null 2>&1; then
  echo 'Unexpected shell in distroless image' >&2
  exit 1
fi
echo 'PASS: /bin/sh is absent'
if docker exec "$container" apt-get --version >/dev/null 2>&1; then
  echo 'Unexpected package manager in distroless image' >&2
  exit 1
fi
echo 'PASS: apt-get is absent'
