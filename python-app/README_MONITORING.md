# Dice Roller with System Monitoring

This Flask application provides a dice rolling service with integrated CPU and memory monitoring using OpenTelemetry.

## Features

### Existing Functionality (Preserved)
- `/health` - Health check endpoint
- `/rolldice` - Roll a dice (returns 1-6)
- OpenTelemetry tracing and metrics integration
- Dice roll counter metrics

### New CPU & Memory Monitoring Features
- Real-time CPU usage monitoring
- Memory usage monitoring (percentage and bytes)
- System metrics exposed via OpenTelemetry
- Background metrics collection every 5 seconds
- Enhanced tracing with system metrics in spans

## Endpoints

### `/health`
Returns the health status of the service.
```json
{"status": "healthy", "service": "dice-server"}
```

### `/rolldice` 
Rolls a dice and returns a random number between 1-6.
- Now includes system metrics in the OpenTelemetry span
- Continues to increment the roll counter metric

### `/metrics` (NEW)
Returns current system resource usage.
```json
{
  "cpu_usage_percent": 15.2,
  "memory_usage_percent": 68.4,
  "memory_usage_bytes": 8589934592,
  "memory_usage_mb": 8192.0
}
```

## OpenTelemetry Metrics

The application now exports the following metrics:

### Existing Metrics
- `roll_counter` - Counter for dice rolls grouped by roll value

### New System Metrics  
- `system_cpu_usage_percent` - Current CPU usage percentage
- `system_memory_usage_percent` - Current memory usage percentage
- `system_memory_usage_bytes` - Current memory usage in bytes

## Installation & Running

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the application:
```bash
python app.py
```

3. Test the monitoring (optional):
```bash
python test_monitoring.py
```

## Technical Implementation

### Architecture
- **Background Thread**: Collects system metrics every 5 seconds using `psutil`
- **Observable Gauges**: OpenTelemetry gauges that report current metric values
- **Thread-Safe**: Uses a shared dictionary with daemon thread for metrics collection
- **Non-Blocking**: System monitoring runs independently and doesn't affect request handling

### Dependencies Added
- `psutil` - For system resource monitoring
- `requests` - For testing script

### Monitoring Details
- CPU usage is averaged over 1-second intervals
- Memory metrics include both percentage and absolute bytes
- Metrics are updated every 5 seconds in the background
- All metrics are automatically exported via OpenTelemetry

## Kubernetes Integration

The existing OpenTelemetry collector configuration in `kubernetes/otel-collector-configmap.yaml` will automatically collect and forward the new system metrics along with the existing ones.

## Error Handling

- System metrics collection includes error handling
- Failed metric collections are logged but don't crash the application
- The daemon thread ensures metrics collection continues even if individual collections fail

## Compatibility

This implementation:
- ✅ Preserves all existing functionality
- ✅ Maintains existing API endpoints
- ✅ Keeps existing OpenTelemetry configuration
- ✅ Adds new features without breaking changes
- ✅ Works with existing Kubernetes deployment
