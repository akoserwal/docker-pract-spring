# Spring Boot Docker labs

Seven hands-on labs use one Java 21 Spring Boot application to teach image building, layer caching, multi-stage builds, permissions, distroless images, health probes, and PostgreSQL with Compose.

Run commands from the repository root. Docker with Compose v2, or a compatible Podman setup, is required. Every image builds the Spring Boot application inside a Maven builder stage; no host JDK or Maven is required.

| Lab | Topic | Starting point |
| --- | --- | --- |
| [1](labs/01-basic-dockerfile/README.md) | Baseline fat JAR image | `labs/01-basic-dockerfile/Dockerfile.naive` |
| [2](labs/02-layered-jars/README.md) | Spring Boot layered JAR and cache | `labs/02-layered-jars/Dockerfile.layered` |
| [3](labs/03-multistage-builds/README.md) | Multi-stage and custom JRE | `labs/03-multistage-builds/Dockerfile.multistage` |
| [4](labs/04-security-and-permissions/README.md) | Non-root and read-only filesystem | `labs/04-security-and-permissions/test-security.sh` |
| [5](labs/05-distroless-hardened/README.md) | Distroless Java runtime | `labs/05-distroless-hardened/verify-no-shell.sh` |
| [6](labs/06-healthchecks-observability/README.md) | Actuator probes and graceful shutdown | `labs/06-healthchecks-observability/compose.health.yaml` |
| [7](labs/07-compose-postgres/README.md) | PostgreSQL, persistence, and Compose | `labs/07-compose-postgres/compose.yaml` |

The app exposes `/actuator/health/readiness`, `/api/v1/items`, and `/api/v1/workload/jvm-info`. The default database is in-memory H2, so item data disappears when the app stops.

For deployments, read the [production guide](docs/production.md). For private Maven repositories, use the [Maven `settings.xml` guide](docs/maven-settings.md).
