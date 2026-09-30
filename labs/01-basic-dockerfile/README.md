# Lab 1: Docker & Spring Boot Fundamentals

Welcome to Module 1! In this lab, you explore the fundamentals of containerizing a Spring Boot 3 application on Java 21, observe how the JVM interacts with Linux container cgroups, and analyze the flaws of the traditional "Fat JAR" Dockerfile.

---

## 1. Concepts & Objectives

By the end of this lab, you will understand:
1. **The JVM in Containers**: How modern OpenJDK runtimes detect cgroups v2 memory and CPU quotas.
2. **The Naive Fat JAR Anti-Pattern**: Why copying an entire 50MB+ `.jar` into a single layer destroys Docker build cache efficiency.
3. **Container Lifecycle Basics**: Port publishing (`-p 127.0.0.1:8080:8080`), environment variables, and inspecting image layers with `docker history`.

---

## 2. The Naive Approach: `Dockerfile.naive`

Take a look at [`Dockerfile.naive`](Dockerfile.naive):
```dockerfile
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder
# Build the Spring Boot JAR here.

FROM eclipse-temurin:21-jdk AS runtime
WORKDIR /app
COPY --from=builder /build/target/docker-prac-spring-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT java -jar app.jar
```

### Why is this problematic?
1. **Layer Invalidation**: Even a 1-character typo fix in your Java code changes the checksum of the entire `.jar`. Docker is forced to re-upload the entire 50MB+ layer on every push.
2. **Bloated Base Image**: Uses a full JDK (~450MB) instead of a minimal JRE or Distroless image (~150MB).
3. **Root Privilege Hazard**: Runs as default `root` (UID 0), violating least-privilege security principles.
4. **Broken Signal Handling**: `ENTRYPOINT java -jar app.jar` uses the **shell form** (`/bin/sh -c ...`). The shell can interfere with delivery of `SIGTERM` to the JVM, delaying graceful shutdown.

---

## 3. Hands-On Exercise

### Step 1: Build the naive image
```bash
docker build -f labs/01-basic-dockerfile/Dockerfile.naive -t spring-boot-naive:1.0 .
```

### Step 2: Inspect image layers
Run `docker history` to see the size of each layer:
```bash
docker history spring-boot-naive:1.0
```
Notice how `COPY --from=builder /build/target/docker-prac-spring-1.0.0.jar app.jar` creates a monolithic layer containing both your 20KB application classes and 50MB of third-party Spring dependencies.

### Step 3: Run the container and test JVM ergonomics
Start the container with a restricted memory limit (512MB) and CPU limit (1.5 cores):
```bash
docker run -d --name spring-naive \
  -p 127.0.0.1:8080:8080 \
  --memory=512m \
  --cpus=1.5 \
  spring-boot-naive:1.0
```

Verify that the JVM detects the container memory and CPU limits automatically via our workload endpoint:
```bash
curl http://localhost:8080/api/v1/workload/jvm-info
```

The values depend on the Docker engine and JVM. Compare `availableProcessors` and `maxMemoryMb` with the requested limits; Java 21 commonly uses a 25% maximum heap percentage by default.

### Step 4: Clean up
```bash
docker stop spring-naive
docker rm spring-naive
```

---

## 4. Key Takeaways
- Never use the **shell form** for `ENTRYPOINT`; always use the **exec JSON array form**: `ENTRYPOINT ["java", "-jar", "app.jar"]`.
- The JVM is container-aware, but default memory allocations are conservative. In production, we configure `-XX:MaxRAMPercentage=75.0`.
- In **Lab 2**, we will break apart this monolithic JAR using Spring Boot 3 Layered JARs to improve layer cache reuse!
