# Complete OpenTelemetry Setup with Flask App and Kafka on Kubernetes

This guide provides step-by-step instructions to deploy a complete observability stack including Flask application, OpenTelemetry Collector, and Kafka cluster.

## 📋 Prerequisites

- **Kubernetes cluster** (minikube, kind, Docker Desktop, or cloud provider)
- **kubectl** configured and connected to your cluster
- **Helm 3.x** installed for Kafka deployment
- **Internet access** to pull images and charts
- **Docker** (if building custom images)

## 🎯 Architecture Overview

```sh
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flask App     │───▶│ OTel Collector   │───▶│   KloudMate     │
│ (dice-server)   │    │                  │    │   Platform      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│ Kafka Cluster   │    │ Kubernetes       │
│  (KRaft mode)   │    │ Infrastructure   │
└─────────────────┘    └──────────────────┘
```

## 🚀 Quick Start (Complete Setup)

### Step 1: Create Namespace

```bash
kubectl create namespace kloudmate
```

### Step 2: Deploy OpenTelemetry Collector

```bash
# Deploy RBAC (for Kubernetes metrics collection)
kubectl apply -f otel-collector-rbac.yaml

# Deploy collector configuration and service
kubectl apply -f otel-collector-configmap.yaml
kubectl apply -f otel-collector-deployment.yaml
kubectl apply -f otel-collector-service.yaml
```

**⚠️ Important**: Update the KloudMate API key in `otel-collector-configmap.yaml`:

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

# Deploy minimal Kafka cluster
cd kafka/
helm install kafka bitnami/kafka -n kloudmate -f minimal-values.yaml
```

### Step 5: Deploy Sample Producer (Optional)

```bash
# Deploy a job that sends sample messages to Kafka
kubectl apply -f kafka/sample-producer-job.yaml
```

## 🔍 Verification Steps

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
- `kafka-controller-headless` (Kafka headless service)
- `otel-collector-service` (OpenTelemetry Collector)

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

## 📊 What Gets Collected

### Flask Application Telemetry

- **Traces**: HTTP request spans with timing and metadata
- **Metrics**: Request duration, active requests, response codes
- **Logs**: Application logs and access logs

### Kubernetes Infrastructure

- **kubeletstats**: Node and pod resource metrics
- **Health checks**: Collector and application health status

### Kafka Metrics (Optional)

- **JMX metrics**: Broker performance data
- **Topic metrics**: Message throughput and lag

## 🔧 Configuration Details

### OpenTelemetry Collector

**Key configuration in `otel-collector-configmap.yaml`:**

```yaml
receivers:
  otlp:                    # Receives telemetry from Flask app
  kubeletstats:           # Collects Kubernetes metrics

processors:
  batch:                  # Batches data for efficiency

exporters:
  debug:                  # Local debugging output
  otlphttp:              # Exports to KloudMate platform

service:
  pipelines:
    traces: [otlp] → [batch] → [debug, otlphttp]
    metrics: [otlp, kubeletstats] → [batch] → [debug, otlphttp]
    logs: [otlp] → [batch] → [debug, otlphttp]
```

### Flask Application

**OpenTelemetry instrumentation:**

- Auto-instrumentation for Flask framework
- OTLP exporter sending to collector
- Configured via environment variables

### Kafka Setup

**Minimal KRaft configuration:**

- Single controller node (no ZooKeeper)
- No authentication (demo purposes)
- Internal cluster access only
- Resource optimized for testing

## 🚨 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status and events
kubectl describe pod <pod-name> -n kloudmate
kubectl get events -n kloudmate --sort-by='.lastTimestamp'
```

**Common causes:**

- Image pull errors
- Resource constraints
- Configuration errors

#### 2. OpenTelemetry Collector Issues

```bash
# Check collector logs
kubectl logs deployment/otel-collector -n kloudmate

# Common issues:
# - Invalid YAML configuration
# - Network connectivity to KloudMate
# - Missing RBAC permissions
```

#### 3. Kafka Connection Problems

```bash
# Check Kafka controller status
kubectl logs kafka-controller-0 -n kloudmate

# Test connectivity
kubectl exec -it kafka-controller-0 -n kloudmate -- \
  kafka-topics.sh --list --bootstrap-server localhost:9092
```

#### 4. Flask App Not Sending Telemetry

```bash
# Check app logs for OpenTelemetry initialization
kubectl logs deployment/dice-app -n kloudmate

# Verify collector is receiving data
kubectl logs deployment/otel-collector -n kloudmate | grep "dice-server"
```

### Network Connectivity Test

Test KloudMate connectivity from cluster:

```bash
kubectl run test-connectivity --rm -i --tty --image=curlimages/curl -- \
  curl -v https://otel.kloudmate.com:4318/v1/traces \
  -H "Authorization: <YOUR_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"test":"connectivity"}'
```

**Expected response:** `200 OK` with `{"partialSuccess":{}}`

## 📝 Important Notes

### Security Considerations

- **API Keys**: Never commit real API keys to version control
- **Network Policies**: Consider implementing network policies for production
- **RBAC**: Review and minimize permissions as needed

### Resource Management

- **Limits**: Set appropriate resource limits for production
- **Monitoring**: Monitor resource usage and adjust as needed
- **Scaling**: Consider horizontal scaling for high-load scenarios

### Production Readiness

- **Persistence**: Enable persistence for Kafka in production
- **High Availability**: Deploy multiple replicas for critical components
- **Backup**: Implement backup strategies for configuration and data

## 🔄 Cleanup

To remove the entire setup:

```bash
# Remove Kafka
helm uninstall kafka -n kloudmate

# Remove all Kubernetes resources
kubectl delete namespace kloudmate
```

## 📚 Additional Resources

- **Kafka Setup Details**: See `kafka/README.md` and `kafka/minimal-setup.md`
- **OpenTelemetry Documentation**: [opentelemetry.io](https://opentelemetry.io)
- **KloudMate Platform**: Check your KloudMate dashboard for received telemetry

## 🎯 Success Criteria

Your setup is working correctly when:

1. ✅ All pods show `Running` status
2. ✅ Flask app responds to HTTP requests
3. ✅ OpenTelemetry collector processes telemetry data
4. ✅ Kafka controller accepts producer connections
5. ✅ Data appears in KloudMate dashboard (if configured correctly)

---

**Next Steps**: Once everything is running, explore the collected telemetry data in your KloudMate dashboard to see traces, metrics, and logs from your Flask application and Kubernetes infrastructure.

```bash
# Check all pods in kloudmate namespace
kubectl get pods -n kloudmate

# Check services in kloudmate namespace
kubectl get svc -n kloudmate

# Check logs
kubectl logs -f deployment/otel-collector -n kloudmate
kubectl logs -f deployment/dice-app -n kloudmate
```

## Access the Application

### Using NodePort (for minikube/local)

```bash
# Get minikube IP
minikube ip

# Access the app
curl http://<minikube-ip>:30081/rolldice

# Access collector (if needed)
curl http://<minikube-ip>:30317
```

### Using kubectl port-forward

```bash
# Forward dice-app port
kubectl port-forward service/dice-app-service 8081:8081

# Access at http://localhost:8081/rolldice

# Forward collector port (optional)
kubectl port-forward service/otel-collector-service 4317:4317 -n monitoring
```

## Architecture

```sh
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────┐
│   Dice App      │───▶│  OpenTelemetry       │───▶│   Kloudmate     │
│   (Port 8081)   │    │  Collector           │    │   Dashboard     │
│   3 replicas    │    │  (Port 4317/4318)    │    │                 │
└─────────────────┘    │  2 replicas          │    └─────────────────┘
                       └──────────────────────┘
```

## Scaling

```bash
# Scale dice-app
kubectl scale deployment dice-app --replicas=5

# Scale collector
kubectl scale deployment otel-collector --replicas=3 -n monitoring
```

## Troubleshooting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check service endpoints
kubectl get endpoints

# Check logs
kubectl logs <pod-name> -f

# Check configuration
kubectl get configmap otel-collector-config -n monitoring -o yaml
```

## Cleanup

```bash
kubectl delete -f dice-app-service.yaml
kubectl delete -f dice-app-deployment.yaml
kubectl delete -f otel-collector-service.yaml
kubectl delete -f otel-collector-deployment.yaml
kubectl delete -f otel-collector-configmap.yaml
kubectl delete -f namespace.yaml
```
