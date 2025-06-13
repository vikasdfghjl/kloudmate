# Minimal Kafka Setup for Testing

This guide provides a minimal Kafka deployment in KRaft mode (no ZooKeeper) suitable for testing and development in the `kloudmate` namespace.

## Prerequisites

- Kubernetes cluster running
- Helm 3.x installed
- `kloudmate` namespace created

## Quick Setup (KRaft Mode)

### 1. Add Bitnami Helm Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Deploy Minimal Kafka

Use the provided minimal values file:

```bash
helm install kafka bitnami/kafka -n kloudmate -f minimal-values.yaml
```

The `minimal-values.yaml` configures:

- Single controller node (no separate brokers)
- KRaft mode (no ZooKeeper dependency)
- Minimal resource requests
- No external access (internal cluster only)

### 3. Verify Deployment

Check that the Kafka controller is running:

```bash
kubectl get pods -n kloudmate
```

Expected output:

```text
NAME                             READY   STATUS    RESTARTS      AGE
dice-app-7cf59786c4-hzhfk        1/1     Running   1 (33m ago)   77m
kafka-controller-0               1/1     Running   0             60s
otel-collector-c5c85f6f4-qjqgd   1/1     Running   1 (32m ago)   60m
```

✅ **Success**: If you see `kafka-controller-0` with status `Running`, your minimal Kafka setup is working!

## Test Kafka Connectivity

### Create a Test Topic

```bash
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-topics.sh \
  --create --topic test-topic \
  --bootstrap-server localhost:9092 \
  --partitions 1 --replication-factor 1
```

### List Topics

```bash
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-topics.sh \
  --list --bootstrap-server localhost:9092
```

### Send Test Messages

```bash
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

Type your message and press Enter. Use Ctrl+C to exit.

### Read Messages

```bash
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic --from-beginning
```

## Connection Details

- **Internal cluster**: `kafka.kloudmate.svc.cluster.local:9092`
- **From same namespace**: `kafka:9092`

## Troubleshooting

### Check Kafka Logs

```bash
kubectl logs kafka-controller-0 -n kloudmate
```

### Check Resources

```bash
kubectl get all -n kloudmate | grep kafka
```

### Check Events

```bash
kubectl get events -n kloudmate --sort-by='.lastTimestamp'
```

## Clean Up

```bash
helm uninstall kafka -n kloudmate
```

## Features of This Setup

- ✅ **Single controller** (1 pod total)
- ✅ **No ZooKeeper needed** (modern Kafka)
- ✅ **Minimal resources** (256Mi RAM, 100m CPU)
- ✅ **Faster startup**
- ✅ **Perfect for development/testing**

This KRaft mode setup is the recommended approach for modern Kafka deployments! 🚀
