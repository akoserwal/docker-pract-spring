# Lab 7: Spring Boot and PostgreSQL with Compose

This lab connects the same app to PostgreSQL. Compose waits for `pg_isready` before starting Spring Boot. PostgreSQL stores items in a named volume. A small sidecar checks Spring Boot's Actuator readiness endpoint because the distroless app image has no shell or curl.

Run these commands from the repository root:

1. Copy `labs/07-compose-postgres/.env.example` to `labs/07-compose-postgres/.env` and set a unique `POSTGRES_PASSWORD` there. The `.env` file is ignored by Git. This is a local development credential; use a secret provider for production.
2. Validate and start the stack:

   ```bash
   docker compose --env-file labs/07-compose-postgres/.env \
     -f labs/07-compose-postgres/compose.yaml config --quiet
   docker compose --env-file labs/07-compose-postgres/.env \
     -f labs/07-compose-postgres/compose.yaml up --build -d
   docker compose --env-file labs/07-compose-postgres/.env \
     -f labs/07-compose-postgres/compose.yaml ps
   ```

3. Check the app and create an item:

   ```bash
   curl --fail http://127.0.0.1:8080/actuator/health/readiness
   curl --fail -X POST http://127.0.0.1:8080/api/v1/items \
     -H 'Content-Type: application/json' \
     -d '{"name":"Compose lab","description":"Stored in PostgreSQL"}'
   curl --fail http://127.0.0.1:8080/api/v1/items
   ```

4. Restart only the app and query the items again. The record should remain because PostgreSQL has its own volume:

   ```bash
   docker compose --env-file labs/07-compose-postgres/.env \
     -f labs/07-compose-postgres/compose.yaml restart app
   curl --fail http://127.0.0.1:8080/api/v1/items
   ```

The database port is private to the Compose network. Only the app is published, on host loopback. The `app-health` service is the readiness signal to inspect in `compose ps`.

For a private Maven registry, read [the Maven settings guide](../../docs/maven-settings.md). Docker Compose with BuildKit can add `-f labs/07-compose-postgres/compose.maven.yaml` after the main Compose file when building, with `MAVEN_SETTINGS_PATH` set to your existing `settings.xml`. On Podman setups where the external Compose provider reports that its classic builder does not support secrets, build the tagged app image directly:

```bash
docker build --secret id=maven-settings,src="$HOME/.m2/settings.xml" \
  -f labs/05-distroless-hardened/Dockerfile.distroless \
  -t spring-boot-postgres-lab-app:1.0 .
docker compose --env-file labs/07-compose-postgres/.env \
  -f labs/07-compose-postgres/compose.yaml up --no-build -d
```

The build secret is never mounted into the running app container.

To stop the lab, run `docker compose --env-file labs/07-compose-postgres/.env -f labs/07-compose-postgres/compose.yaml down`. This removes the lab containers and network but keeps the PostgreSQL volume and its data. Do not add `--volumes` unless you intend to delete that data.

For Podman with a stale `DOCKER_HOST=unix:///tmp/podman.sock`, point `DOCKER_HOST` at the active Docker-compatible socket before using `docker compose` (on this machine, `unix:///var/run/docker.sock`).
