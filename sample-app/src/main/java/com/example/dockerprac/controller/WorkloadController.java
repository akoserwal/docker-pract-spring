package com.example.dockerprac.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.lang.management.ManagementFactory;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/workload")
public class WorkloadController {

    private static final Logger log = LoggerFactory.getLogger(WorkloadController.class);

    /**
     * Endpoint to observe JVM container ergonomics (memory limits, cgroups, cpu count).
     */
    @GetMapping("/jvm-info")
    public ResponseEntity<Map<String, Object>> getJvmInfo() {
        Runtime runtime = Runtime.getRuntime();
        Map<String, Object> info = new HashMap<>();

        info.put("availableProcessors", runtime.availableProcessors());
        info.put("maxMemoryMb", runtime.maxMemory() / (1024 * 1024));
        info.put("totalMemoryMb", runtime.totalMemory() / (1024 * 1024));
        info.put("freeMemoryMb", runtime.freeMemory() / (1024 * 1024));
        info.put("jvmArguments", ManagementFactory.getRuntimeMXBean().getInputArguments());

        return ResponseEntity.ok(info);
    }

    /**
     * Simulates a long-running request to demonstrate graceful shutdown and SIGTERM handling.
     */
    @GetMapping("/slow")
    public ResponseEntity<Map<String, String>> simulateSlowRequest(
            @RequestParam(defaultValue = "5000") long delayMs) {
        log.info("Starting slow request processing ({} ms)...", delayMs);
        try {
            Thread.sleep(delayMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Request interrupted during shutdown window!");
            return ResponseEntity.status(503).body(Map.of("status", "interrupted"));
        }
        log.info("Completed slow request successfully.");
        return ResponseEntity.ok(Map.of(
                "status", "completed",
                "processedDurationMs", String.valueOf(delayMs)
        ));
    }
}
