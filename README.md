# Flask App with OpenTelemetry and Kafka on Kubernetes

This project demonstrates a complete observability setup with:

- **Flask Application** with OpenTelemetry instrumentation
- **OpenTelemetry Collector** forwarding telemetry to Kloudmate
- **Minimal Kafka Cluster** for event streaming (KRaft mode)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flask App     │───▶│ OTel Collector   │───▶│   Kloudmate     │
│ (dice-server)   │    │                  │    │   Platform      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                              
         ▼                                              
┌─────────────────┐                                     
│ Kafka Cluster   │                                     
│  (KRaft mode)   │                                     
└─────────────────┘                                     
```

## Components

### 1. Flask Application (`python-app/`)

- **Endpoint**: `/roll` - Returns a random dice roll
- **Health Check**: `/health` - Kubernetes readiness probe
- **Instrumentation**: 
  - Traces for HTTP requests
  - Metrics for request counts and latencies  
  - Logs with structured format
- **Docker Image**: `vikasdfghjl/dice-server:latest`

### 2. OpenTelemetry Collector (`kubernetes/`)

- **Purpose**: Collects and forwards telemetry data
- **Configuration**: Batch processing, health checks
- **Destination**: Kloudmate platform
- **Namespace**: `kloudmate`

### 3. Kafka Cluster (`kubernetes/kafka/`)

- **Mode**: KRaft (no ZooKeeper dependency)
- **Configuration**: Single controller node
- **Use Case**: Event streaming and message queue testing
- **Namespace**: `kloudmate`

## Quick Start

### Prerequisites

- Kubernetes cluster
- Helm 3.x
- Docker (for building images)

### Deploy Everything

1. **Create namespace**:
   ```bash
   kubectl create namespace kloudmate
   ```

2. **Deploy Flask app**:
   ```bash
   kubectl apply -f kubernetes/dice-app-deployment.yaml
   kubectl apply -f kubernetes/dice-app-service.yaml
   ```

3. **Deploy OpenTelemetry Collector**:
   ```bash
   kubectl apply -f kubernetes/otel-collector-configmap.yaml
   kubectl apply -f kubernetes/otel-collector-deployment.yaml
   kubectl apply -f kubernetes/otel-collector-service.yaml
   ```

4. **Deploy Kafka**:
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm install kafka bitnami/kafka -n kloudmate -f kubernetes/kafka/minimal-values.yaml
   ```

### Verify Deployment

Check all pods are running:

```bash
kubectl get pods -n kloudmate
```

Expected output:
```
NAME                             READY   STATUS    RESTARTS   AGE
dice-app-7cf59786c4-hzhfk        1/1     Running   1          77m
kafka-controller-0               1/1     Running   0          60s
otel-collector-c5c85f6f4-qjqgd   1/1     Running   1          60m
```

## Testing

### Test Flask App

```bash
# Port forward to access the app
kubectl port-forward -n kloudmate svc/dice-app-service 5000:5000

# Test the dice roll endpoint
curl http://localhost:5000/roll

# Test health endpoint
curl http://localhost:5000/health
```

### Test Kafka

```bash
# Create a test topic
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# Produce a message
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092
```

## Configuration

### OpenTelemetry Collector

The collector is configured to:
- Receive OTLP traces, metrics, and logs
- Process data in batches for efficiency
- Forward to Kloudmate with API authentication
- Provide health check endpoints

### Kafka Minimal Setup

The Kafka deployment uses:
- Single controller node (minimal resources)
- KRaft mode (no ZooKeeper)
- Internal cluster access only
- Perfect for development/testing

## Monitoring

- **Traces**: HTTP request spans with timing
- **Metrics**: Request counts, response times, system metrics
- **Logs**: Structured application logs
- **Health**: Kubernetes readiness/liveness probes

## Documentation

- [`kubernetes/kafka/README.md`](kubernetes/kafka/README.md) - Detailed Kafka setup
- [`kubernetes/kafka/minimal-setup.md`](kubernetes/kafka/minimal-setup.md) - Step-by-step minimal deployment

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Kafka connection issues**: Verify controller is running and accessible
3. **Telemetry not reaching Kloudmate**: Check API key and network connectivity

### Useful Commands

```bash
# Check pod logs
kubectl logs -n kloudmate <pod-name>

# Debug pod issues
kubectl describe pod -n kloudmate <pod-name>

# Monitor resource usage
kubectl top pods -n kloudmate
```

## Status

✅ **Flask App**: Deployed and running with OpenTelemetry  
✅ **OpenTelemetry Collector**: Forwarding to Kloudmate  
✅ **Kafka Cluster**: Single-node KRaft mode operational  
✅ **Namespace**: All components in `kloudmate` namespace  
✅ **Health Checks**: All pods healthy and ready  

This setup provides a complete observability and messaging foundation for development and testing.