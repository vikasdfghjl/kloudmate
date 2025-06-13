# Deploy Kafka using Bitnami Helm Charts

## Prerequisites

- Kubernetes cluster (minikube or any K8s cluster)
- Helm 3.x installed
- kubectl configured

## Step 1: Install Helm (if not already installed)

### For Windows (using Chocolatey):

```bash
choco install kubernetes-helm
```

### For Windows (using Scoop):

```bash
scoop install helm
```

### For Linux/WSL:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Step 2: Add Bitnami Helm Repository

```bash
# Add the Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update your helm repositories
helm repo update

# Verify the repository is added
helm repo list
```

## Step 3: Create Kafka Values File

Create a custom values file for single broker setup:

```bash
# Create the values file
cat > kafka-values.yaml << EOF
## Kafka configuration
kafka:
  replicaCount: 1
  
## ZooKeeper configuration  
zookeeper:
  enabled: true
  replicaCount: 1
  
## Resource limits for single broker
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 256Mi

## Persistence configuration
persistence:
  enabled: true
  size: 8Gi

## Service configuration
service:
  type: NodePort
  nodePorts:
    client: 30092

## External access (optional)
externalAccess:
  enabled: false
EOF
```

## Step 4: Deploy Kafka

```bash
# Use existing kloudmate namespace (no need to create new namespace)
# kubectl create namespace kloudmate  # Already exists

# Install Kafka using Helm in kloudmate namespace
helm install kafka bitnami/kafka \
  --namespace kloudmate \
  --values kafka-values.yaml \
  --set kafka.replicaCount=1 \
  --set zookeeper.replicaCount=1

# Or install with inline values (simpler)
helm install kafka bitnami/kafka \
  --namespace kloudmate \
  --set kafka.replicaCount=1 \
  --set zookeeper.replicaCount=1 \
  --set kafka.persistence.size=8Gi \
  --set service.type=NodePort \
  --set service.nodePorts.client=30092
```

## Step 5: Verify Deployment

```bash
# Check all pods in kloudmate namespace (including your existing apps)
kubectl get pods -n kloudmate

# Check services in kloudmate namespace
kubectl get svc -n kloudmate

# Get detailed info for entire kloudmate namespace
kubectl get all -n kloudmate
```

## Step 6: Access Kafka

### Get Kafka Connection Details:
```bash
# Get the NodePort service
kubectl get svc kafka -n kafka

# For minikube, get the IP
minikube ip

# Kafka will be accessible at: <minikube-ip>:30092
```

### Test Kafka Connection:
```bash
# Create a test producer pod
kubectl run kafka-producer \
  --image=bitnami/kafka:latest \
  --rm -it --restart=Never \
  --namespace kloudmate \
  --command -- kafka-console-producer.sh \
  --bootstrap-server kafka.kloudmate.svc.cluster.local:9092 \
  --topic test-topic

# In another terminal, create a consumer
kubectl run kafka-consumer \
  --image=bitnami/kafka:latest \
  --rm -it --restart=Never \
  --namespace kloudmate \
  --command -- kafka-console-consumer.sh \
  --bootstrap-server kafka.kloudmate.svc.cluster.local:9092 \
  --topic test-topic \
  --from-beginning
```

## Step 7: Create Topics (Optional)

```bash
# Create a topic for your application
kubectl run kafka-topics \
  --image=bitnami/kafka:latest \
  --rm -it --restart=Never \
  --namespace kloudmate \
  --command -- kafka-topics.sh \
  --bootstrap-server kafka.kloudmate.svc.cluster.local:9092 \
  --create \
  --topic dice-events \
  --partitions 1 \
  --replication-factor 1

# List topics
kubectl run kafka-topics \
  --image=bitnami/kafka:latest \
  --rm -it --restart=Never \
  --namespace kloudmate \
  --command -- kafka-topics.sh \
  --bootstrap-server kafka.kloudmate.svc.cluster.local:9092 \
  --list
```

## Step 8: Integration with Your App

For connecting your dice app to Kafka, you can use:
- **Internal connection**: `kafka.kloudmate.svc.cluster.local:9092`
- **External connection**: `<minikube-ip>:30092`

## Useful Commands

```bash
# Check Kafka logs
kubectl logs -f deployment/kafka -n kloudmate

# Check ZooKeeper logs  
kubectl logs -f deployment/kafka-zookeeper -n kloudmate

# Get Kafka status
helm status kafka -n kloudmate

# Upgrade Kafka
helm upgrade kafka bitnami/kafka --namespace kloudmate --values kafka-values.yaml

# Uninstall Kafka
helm uninstall kafka -n kloudmate
# Note: namespace kloudmate will still exist with your other apps
```

## Expected Resources

After deployment, you should see:
- 1 Kafka broker pod
- 1 ZooKeeper pod  
- Kafka service (ClusterIP and NodePort)
- ZooKeeper service
- PersistentVolumes for data storage

## Troubleshooting

```bash
# Check pod events
kubectl describe pod <kafka-pod-name> -n kafka

# Check persistent volumes
kubectl get pv

# Check storage classes
kubectl get storageclass
```

This setup provides a minimal but production-ready single-broker Kafka cluster perfect for development and testing!
