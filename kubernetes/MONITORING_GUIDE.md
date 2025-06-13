# Kubernetes CPU and Memory Monitoring with OpenTelemetry

This configuration uses the OpenTelemetry Collector's `kubeletstats` receiver to collect comprehensive CPU and memory metrics from your Kubernetes cluster.

## Metrics Collected

### Node-Level Metrics
- `k8s.node.cpu.usage` - CPU usage for the entire node
- `k8s.node.memory.usage` - Memory usage for the entire node  
- `k8s.node.memory.available` - Available memory on the node

### Pod-Level Metrics
- `k8s.pod.cpu.usage` - CPU usage per pod (including your dice-app)
- `k8s.pod.memory.usage` - Memory usage per pod
- `k8s.pod.memory.available` - Available memory per pod

### Container-Level Metrics
- `k8s.container.cpu.usage` - CPU usage per container
- `k8s.container.memory.usage` - Memory usage per container
- `k8s.container.memory.available` - Available memory per container
- `k8s.container.restarts` - Container restart count

## Configuration Changes Made

1. **Enhanced kubeletstats receiver:**
   - Reduced collection interval from 60s to 30s for more frequent updates
   - Added specific metric groups: node, pod, container
   - Enabled specific CPU and memory metrics
   - Added container restart monitoring

2. **Added resource detection processor:**
   - Automatically detects Kubernetes node and pod information
   - Adds resource attributes for better metric identification

3. **Added resource processor:**
   - Tags all metrics with service name "dice-app"
   - Adds deployment environment label

## How It Works

1. The OpenTelemetry collector runs as a DaemonSet in your cluster
2. It connects to the kubelet API on each node (`https://${K8S_NODE_NAME}:10250`)
3. Collects metrics every 30 seconds
4. Processes and enriches the metrics with resource information
5. Exports to your kloudmate.com endpoint

## Monitoring Your Dice App

With this configuration, you can monitor:

- **CPU Usage**: How much CPU your dice-app pods are consuming
- **Memory Usage**: Memory consumption of your dice-app containers
- **Resource Efficiency**: Compare usage across different pods
- **Performance Issues**: Identify pods with high resource usage
- **Restart Patterns**: Track if containers are restarting frequently

## Deployment

To apply the updated configuration:

```bash
kubectl apply -f kubernetes/otel-collector-configmap.yaml
kubectl rollout restart daemonset/otel-collector -n kloudmate
```

## Verification

Check if metrics are being collected:

```bash
# Check collector logs
kubectl logs -l app=otel-collector -n kloudmate

# Check if metrics are being exported (look for kubeletstats metrics)
kubectl logs -l app=otel-collector -n kloudmate | grep "kubeletstats"
```

## Resource Attributes

Each metric will include these attributes for filtering and grouping:
- `k8s.node.name` - The Kubernetes node name
- `k8s.pod.name` - The pod name
- `k8s.container.name` - The container name
- `service.name` - Set to "dice-app"
- `deployment.environment` - Set to "production"

This allows you to create dashboards and alerts specifically for your dice application while still seeing the broader cluster metrics.
