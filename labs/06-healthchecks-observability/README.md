# Lab 6: Spring Boot health probes and graceful shutdown

This lab runs the distroless image from Lab 5 with a separate health checker. Spring Boot Actuator exposes `/actuator/health/liveness` and `/actuator/health/readiness` because probes are enabled in `sample-app/src/main/resources/application.yaml`.

From the repository root, use the following commands. If your Podman-backed `docker` command has `DOCKER_HOST=unix:///tmp/podman.sock` but that socket does not exist, first set `DOCKER_HOST=unix:///var/run/docker.sock` in the same terminal.

```bash
docker compose -f labs/06-healthchecks-observability/compose.health.yaml config --quiet
docker compose -f labs/06-healthchecks-observability/compose.health.yaml up --build -d
docker compose -f labs/06-healthchecks-observability/compose.health.yaml ps
curl --fail http://127.0.0.1:8080/actuator/health/readiness
```

The `app-health` sidecar checks readiness over the app's network namespace. The distroless app needs no shell or HTTP client. Compose reports health on the sidecar, so inspect `app-health` in `compose ps`.

To observe graceful shutdown, start a slow request, then stop the app in another terminal:

```bash
curl 'http://127.0.0.1:8080/api/v1/workload/slow?delayMs=5000'
```

```bash
docker compose -f labs/06-healthchecks-observability/compose.health.yaml stop app
```

Spring Boot has a 20-second shutdown phase and Compose grants 30 seconds. The in-flight request should finish within that window. Restart with `docker compose -f labs/06-healthchecks-observability/compose.health.yaml start app`.

When finished, `docker compose -f labs/06-healthchecks-observability/compose.health.yaml down` stops and removes this lab's containers and network. It does not delete any volumes.
