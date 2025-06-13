# PowerShell script to deploy the updated OpenTelemetry collector configuration
# for enhanced CPU and memory monitoring

Write-Host "🚀 Deploying Enhanced OpenTelemetry Collector Configuration" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

# Validate YAML syntax
Write-Host "1. Validating YAML syntax..." -ForegroundColor Yellow
try {
    kubectl apply --dry-run=client -f kubernetes/otel-collector-configmap.yaml | Out-Null
    Write-Host "✅ YAML syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "❌ YAML syntax error. Please check the file." -ForegroundColor Red
    exit 1
}

# Apply the configuration
Write-Host "2. Applying updated ConfigMap..." -ForegroundColor Yellow
kubectl apply -f kubernetes/otel-collector-configmap.yaml

# Restart the collector to pick up new configuration
Write-Host "3. Restarting OpenTelemetry collector..." -ForegroundColor Yellow
kubectl rollout restart daemonset/otel-collector -n kloudmate

# Wait for rollout to complete
Write-Host "4. Waiting for rollout to complete..." -ForegroundColor Yellow
kubectl rollout status daemonset/otel-collector -n kloudmate --timeout=300s

# Check if pods are running
Write-Host "5. Checking collector pod status..." -ForegroundColor Yellow
kubectl get pods -l app=otel-collector -n kloudmate

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 To monitor the collector:" -ForegroundColor Cyan
Write-Host "   kubectl logs -l app=otel-collector -n kloudmate -f" -ForegroundColor White
Write-Host ""
Write-Host "📊 New metrics being collected:" -ForegroundColor Cyan
Write-Host "   - k8s.node.cpu.usage" -ForegroundColor White
Write-Host "   - k8s.node.memory.usage" -ForegroundColor White
Write-Host "   - k8s.pod.cpu.usage" -ForegroundColor White
Write-Host "   - k8s.pod.memory.usage" -ForegroundColor White
Write-Host "   - k8s.container.cpu.usage" -ForegroundColor White
Write-Host "   - k8s.container.memory.usage" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Metrics will be tagged with service.name=dice-app for easy filtering" -ForegroundColor Cyan
