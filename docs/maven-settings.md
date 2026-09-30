# Maven `settings.xml` in container builds

The lab Dockerfiles use public Maven Central by default. If your organization uses a private mirror or repository, keep `settings.xml` outside this repository and pass it to the builder as a temporary build secret. The Maven builder runs both dependency resolution and `mvn package` with the file mounted at `/root/.m2/settings.xml`; the runtime image never contains it. The root `.dockerignore` excludes `settings.xml` as a second safeguard.

Use your existing `~/.m2/settings.xml`, or create one according to your registry's instructions. A mirror entry points Maven at your repository; a matching `<server><id>` holds the authentication Maven needs. For example, the IDs must match:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0">
  <mirrors>
    <mirror>
      <id>company-mirror</id>
      <mirrorOf>*</mirrorOf>
      <url>https://maven.example.org/repository/maven-public/</url>
    </mirror>
  </mirrors>
  <servers>
    <server>
      <id>company-mirror</id>
      <username>YOUR_USER</username>
      <password>YOUR_TOKEN</password>
    </server>
  </servers>
</settings>
```

Replace the example URL and placeholders only in your private file. Restrict its permissions, for example with `chmod 600 "$HOME/.m2/settings.xml"`. Do not paste tokens into a Dockerfile, Compose YAML, build argument, or Git-tracked `.env` file.

Build any lab image with the secret. For example, from the repository root:

```bash
docker build \
  --secret id=maven-settings,src="$HOME/.m2/settings.xml" \
  -f labs/05-distroless-hardened/Dockerfile.distroless \
  -t spring-boot-distroless:1.0 .
```

Build Lab 7 through Docker Compose with its optional override when the Compose provider supports BuildKit secrets:

```bash
export MAVEN_SETTINGS_PATH="$HOME/.m2/settings.xml"
docker compose --env-file labs/07-compose-postgres/.env \
  -f labs/07-compose-postgres/compose.yaml \
  -f labs/07-compose-postgres/compose.maven.yaml build app
```

The override supplies `maven-settings` only to the build. On this machine, Podman's external Compose provider uses a classic builder that rejects build secrets. Use the direct `docker build --secret` command above with `-t spring-boot-postgres-lab-app:1.0`, then run `docker compose --env-file labs/07-compose-postgres/.env -f labs/07-compose-postgres/compose.yaml up --no-build -d`. The public-package path works without a secret. If the private repository credentials rotate, update the source file and rebuild. A build cache may reuse a previously successful dependency step; use your builder's cache controls when you need to force authentication to be checked again. Avoid printing `settings.xml` or resolved Compose configuration in logs.

For more detail, see the [Docker build-secret documentation](https://docs.docker.com/build/building/secrets/) and [Compose build-secret documentation](https://docs.docker.com/compose/how-tos/use-secrets/).
