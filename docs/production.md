# Production guide for the Spring Boot image

The labs are teaching examples. For a deployed service, start from the non-root [distroless image](../labs/05-distroless-hardened/Dockerfile.distroless) or the [hardened JRE image](../labs/04-security-and-permissions/Dockerfile.hardened), then configure the platform around the image. Build once in CI, run the Maven tests, scan the resulting image, and promote the same immutable image digest between environments. Pin base images by digest as part of your normal update process.

## Runtime configuration

The app defaults to in-memory H2. Set `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, and `SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver` for PostgreSQL. Supply credentials through your deployment platform's secret mechanism. Spring Boot can import mounted secret files through a [configuration tree](https://docs.spring.io/spring-boot/reference/features/external-config.html); for example, a file named `spring.datasource.password` mounted under `/run/secrets/` can be read with `SPRING_CONFIG_IMPORT=configtree:/run/secrets/`. Mount the file read-only and grant access only to the app's UID. Keep build-time Maven credentials separate from runtime database credentials.

The sample app uses `spring.jpa.hibernate.ddl-auto=update` to make the local lab easy to start. For production, use versioned database migrations, set `SPRING_JPA_HIBERNATE_DDL_AUTO=validate` after the schema exists, and back up PostgreSQL before applying migrations. The Lab 7 Compose file is a local development stack, not a production deployment manifest.

## Process, health, and exposure

Run with a read-only root filesystem, a writable `/tmp` tmpfs for the JVM and embedded Tomcat, no added Linux capabilities, and a non-root UID. The image starts Java directly, so it receives termination signals. Give the process at least 30 seconds to stop; the app's Spring Boot shutdown phase is configured for 20 seconds.

Use `/actuator/health/liveness` to decide whether to restart the process and `/actuator/health/readiness` before sending traffic. The distroless image has no HTTP client, so place probes in your orchestrator or a health-check sidecar. Restrict exposure of Actuator metrics and details to trusted operators. See the [Spring Boot probe guidance](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html).

Set JVM memory and CPU limits with room for heap, metaspace, thread stacks, and direct memory. The sample sets `-XX:MaxRAMPercentage=75.0`; measure real workload memory before using that percentage in production. Forward stdout and stderr to your log collector, monitor latency and error rates, and alert on readiness failures and database saturation.

## Deployment checks

Before promoting an image, verify a clean image build, passing Maven tests, non-root runtime user, readiness after startup, graceful completion of an in-flight request on shutdown, and a database backup/restore procedure. Roll back by deploying the previous immutable image; plan database migrations so the previous version can still run during a rollback.
