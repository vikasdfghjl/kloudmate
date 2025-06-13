# OpenTelemetry Setup with Flask App and Kafka on Kubernetes

Tstep-by-step instructions to deploy a complete observability stack including Flask application, OpenTelemetry Collector, and Kafka cluster.

## 📋 Prerequisites

- **kubectl** configured and connected to your cluster
- **Helm** installed for Kafka deployment

### Step 1: Create Namespace

```bash
kubectl create namespace kloudmate
```

### Step 2: Deploy OpenTelemetry Collector

```bash
kubectl apply -f otel-collector-rbac.yaml

# Deploy collector configuration and service
kubectl apply -f otel-collector-configmap.yaml
kubectl apply -f otel-collector-deployment.yaml
kubectl apply -f otel-collector-service.yaml
```

**Important**: Update the KloudMate API key in `otel-collector-configmap.yaml`:

```yaml
Authorization: <YOUR_KLOUDMATE_API_KEY>
```

### Step 3: Deploy Flask Application

```bash
kubectl apply -f dice-app-deployment.yaml
kubectl apply -f dice-app-service.yaml
```

### Step 4: Deploy Kafka Cluster

```bash
# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy  Kafka cluster
cd kafka/
helm install kafka bitnami/kafka -n kloudmate -f minimal-values.yaml
```

### Step 5: Deploy Sample Producer

```bash
# Deploy a job that sends sample messages to Kafka
kubectl apply -f kafka/sample-producer-job.yaml
```

### Check All Pods

```bash
kubectl get pods -n kloudmate
```

**Expected output:**

```sh
NAME                              READY   STATUS      RESTARTS   AGE
dice-app-7cf59786c4-hzhfk         1/1     Running     0          5m
kafka-controller-0                2/2     Running     0          3m
otel-collector-66db647bf5-pphqs   1/1     Running     0          4m
kafka-sample-producer-xxxxx       0/1     Completed   0          1m
```

### Check Services

```bash
kubectl get svc -n kloudmate
```

**Expected services:**

- `dice-app-service` (Flask app)
- `kafka` (Kafka broker)
- `kafka-controller-headless` (Kafka service)
- `otel-collector-service` (OTel Collector)

### Test Flask Application

```bash
# Port forward to access the app
kubectl port-forward -n kloudmate svc/dice-app-service 5000:8081

# In another terminal, test the endpoints
curl http://localhost:5000/rolldice  # Dice roll endpoint
curl http://localhost:5000/health    # Health check
```

### Verify OpenTelemetry Collection

```bash
# Check collector logs for telemetry data
kubectl logs -n kloudmate deployment/otel-collector | head -20

# Look for export logs
kubectl logs -n kloudmate deployment/otel-collector | grep -i "traces\|metrics\|logs"
```

### Test Kafka

```bash
# Check Kafka controller logs
kubectl logs kafka-controller-0 -n kloudmate

# Test topic creation
kubectl exec -it kafka-controller-0 -n kloudmate -- kafka-topics.sh \
  --list --bootstrap-server localhost:9092
```

## Troubleshooting

```bash
# Test connectivity
kubectl exec -it <kafka-controller-pod> -n kloudmate -- \
  kafka-topics.sh --list --bootstrap-server localhost:9092

# Check logs
kubectl logs <pod-name> -f
```

### Network Connectivity Test

```bash
kubectl run test-connectivity --rm -i --tty --image=curlimages/curl -- \
  curl -v https://otel.kloudmate.com:4318/v1/traces \
  -H "Authorization: <YOUR_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"test":"connectivity"}'
```

**Expected response:** `200 OK` with `{"partialSuccess":{}}`

### Using kubectl port-forward

```bash
# Forward dice-app port
kubectl port-forward service/dice-app-service 8081:8081

# Access at http://localhost:8081/rolldice
```

## Cleanup

```bash
helm uninstall kafka -n kloudmate

kubectl delete namespace kloudmate
```
