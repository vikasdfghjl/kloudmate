# CPU and Memory Monitoring in Kubernetes

## Overview

Since this application runs on Kubernetes, CPU and memory metrics are collected at the **infrastructure level** rather than within the application code. This is the correct and recommended approach for several reasons:

## Why Infrastructure-Level Monitoring?

1. **Accuracy**: Kubernetes provides accurate resource usage metrics directly from the container runtime
2. **Efficiency**: No need to add monitoring overhead to your application code
3. **Consistency**: All applications in the cluster use the same monitoring approach
4. **Resource Limits**: Kubernetes metrics respect container resource limits and requests

## Current Setup

### OpenTelemetry Collector Configuration

Your `kubernetes/otel-collector-configmap.yaml` already includes the `kubeletstats` receiver:

```yaml
receivers:
  kubeletstats:
    collection_interval: 60s
    auth_type: "serviceAccount"
    endpoint: "https://${env:K8S_NODE_NAME}:10250"
    insecure_skip_verify: true
```

This receiver automatically collects:
- **CPU metrics**: `k8s.pod.cpu.usage`, `k8s.container.cpu.usage`
- **Memory metrics**: `k8s.pod.memory.usage`, `k8s.container.memory.usage`
- **Network metrics**: Pod and container network I/O
- **Filesystem metrics**: Pod and container disk usage

### Application-Level Metrics

The Python application focuses on **business metrics** rather than system metrics:

- `dice_rolls_total`: Counter for total dice rolls
- `dice_roll_duration`: Histogram for roll processing time
- Distributed tracing for request flows

## Benefits of This Approach

1. **Separation of Concerns**: Application focuses on business logic, infrastructure handles system metrics
2. **No Code Overhead**: No need for psutil or similar libraries in your application
3. **Kubernetes Integration**: Metrics are automatically tagged with pod, namespace, and node information
4. **Resource Efficiency**: Single collector handles metrics for all pods on a node

## Viewing Metrics

The kubeletstats receiver provides metrics with labels like:
- `k8s.pod.name`
- `k8s.namespace.name`
- `k8s.container.name`
- `k8s.node.name`

These metrics are exported to your observability platform where you can create dashboards and alerts based on CPU and memory usage per pod, container, or namespace.
