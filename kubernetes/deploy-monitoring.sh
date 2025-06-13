#!/bin/bash

# Script to deploy the updated OpenTelemetry collector configuration
# for enhanced CPU and memory monitoring

echo "🚀 Deploying Enhanced OpenTelemetry Collector Configuration"
echo "============================================================"

# Validate YAML syntax
echo "1. Validating YAML syntax..."
if kubectl apply --dry-run=client -f kubernetes/otel-collector-configmap.yaml; then
    echo "✅ YAML syntax is valid"
else
    echo "❌ YAML syntax error. Please check the file."
    exit 1
fi

# Apply the configuration
echo "2. Applying updated ConfigMap..."
kubectl apply -f kubernetes/otel-collector-configmap.yaml

# Restart the collector to pick up new configuration
echo "3. Restarting OpenTelemetry collector..."
kubectl rollout restart daemonset/otel-collector -n kloudmate

# Wait for rollout to complete
echo "4. Waiting for rollout to complete..."
kubectl rollout status daemonset/otel-collector -n kloudmate --timeout=300s

# Check if pods are running
echo "5. Checking collector pod status..."
kubectl get pods -l app=otel-collector -n kloudmate

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 To monitor the collector:"
echo "   kubectl logs -l app=otel-collector -n kloudmate -f"
echo ""
echo "📊 New metrics being collected:"
echo "   - k8s.node.cpu.usage"
echo "   - k8s.node.memory.usage"
echo "   - k8s.pod.cpu.usage"
echo "   - k8s.pod.memory.usage" 
echo "   - k8s.container.cpu.usage"
echo "   - k8s.container.memory.usage"
echo ""
echo "🎯 Metrics will be tagged with service.name=dice-app for easy filtering"
