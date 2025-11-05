# Configuration Guide

This document explains how to configure the ChatApp with custom IP addresses and service URLs.

## Helm Deployment Configuration

### Setting the External IP and Service URLs

The application uses configurable IP addresses defined in the Helm values files. You can customize these in three ways:

#### 1. Default values.yaml (Development)

Edit `helm/chatapp/values.yaml`:

```yaml
global:
  externalIP: "10.211.13.240"  # Change this to your server IP
  externalServiceURLs:
    goService: "http://10.211.13.240:8080"
    pythonService: "http://10.211.13.240:8091"
    javaService: "http://10.211.13.240:8090"
```

#### 2. Environment-specific values files

**Development** (`helm/chatapp/values-dev.yaml`):
```yaml
global:
  externalIP: "10.211.13.240"
  externalServiceURLs:
    goService: "http://10.211.13.240:8080"
    pythonService: "http://10.211.13.240:8091"
    javaService: "http://10.211.13.240:8090"
```

**Production** (`helm/chatapp/values-prod.yaml`):
```yaml
global:
  externalIP: "your-production-ip"
  externalServiceURLs:
    goService: "http://your-production-ip:8080"
    pythonService: "http://your-production-ip:8091"
    javaService: "http://your-production-ip:8090"
```

#### 3. Override at deployment time

You can override values directly when deploying with Helm:

```bash
helm install chatapp ./helm/chatapp \
  --set global.externalIP="192.168.1.100" \
  --set global.externalServiceURLs.goService="http://192.168.1.100:8080" \
  --set global.externalServiceURLs.pythonService="http://192.168.1.100:8091" \
  --set global.externalServiceURLs.javaService="http://192.168.1.100:8090"
```

Or use environment-specific values:

```bash
# Deploy to development
helm install chatapp ./helm/chatapp -f helm/chatapp/values-dev.yaml

# Deploy to production
helm install chatapp ./helm/chatapp -f helm/chatapp/values-prod.yaml
```

## Standalone index.html Configuration

When using the standalone `index.html` file (not deployed via Helm), you have three options to configure the service URLs:

### Option 1: URL Parameters (Recommended)

Open the application with URL parameters:

```
http://your-server/index.html?serverIP=10.211.13.240&goPort=8080&pythonPort=8091
```

Parameters:
- `serverIP`: The IP address or hostname of your server (default: `localhost`)
- `goPort`: Port for the Go service (default: `8080`)
- `pythonPort`: Port for the Python service (default: `8091`)

### Option 2: JavaScript Configuration Object

Add a configuration script before loading the page:

```html
<script>
  window.chatConfig = {
    serverIP: '10.211.13.240',
    goPort: '8080',
    pythonPort: '8091'
  };
</script>
```

### Option 3: Edit the ConfigMap (Kubernetes)

For Kubernetes deployments, edit the ConfigMap in `k8s/ui-config.yaml`:

```yaml
const GO_SERVICE_URL = 'http://10.211.13.240:8080';
const PYTHON_SERVICE_URL = 'http://10.211.13.240:8091';
```

Then apply the changes:

```bash
kubectl apply -f k8s/ui-config.yaml
kubectl rollout restart deployment/ui -n chatapp
```

## Docker Image Configuration

All services use the `varmasai10/` prefix for Docker images:

- `varmasai10/chatapp-go:latest`
- `varmasai10/chatapp-java:latest`
- `varmasai10/chatapp-python:latest`

These are configured in:
- Helm: `helm/chatapp/values.yaml`
- Kubernetes: `k8s/*-deployment.yaml` files

To use different images, update the `image.repository` values in the respective configuration files.

## Examples

### Example 1: Local Development

```bash
# Access the UI with local services
open http://localhost/index.html?serverIP=localhost&goPort=8080&pythonPort=8091
```

### Example 2: Remote Server

```bash
# Access the UI pointing to a remote server
open http://10.211.13.240/index.html?serverIP=10.211.13.240&goPort=8080&pythonPort=8091
```

### Example 3: Custom Domain

```yaml
# In values-prod.yaml
global:
  externalIP: "chatapp.example.com"
  externalServiceURLs:
    goService: "https://chatapp.example.com/api/go"
    pythonService: "https://chatapp.example.com/api/python"
    javaService: "https://chatapp.example.com/api/java"
```

## Verifying Configuration

After deployment, check the browser console when opening the UI. You should see:

```
Service Configuration: {
  GO_SERVICE_URL: "http://10.211.13.240:8080",
  PYTHON_SERVICE_URL: "http://10.211.13.240:8091"
}
```

This confirms the configuration is loaded correctly.

## Troubleshooting

### CORS Issues

If you encounter CORS errors, make sure your services are configured to allow requests from the UI's origin.

### Connection Refused

- Verify the IP address and ports are correct
- Check that services are running: `kubectl get pods -n chatapp`
- Verify services are exposed: `kubectl get svc -n chatapp`

### URL Parameters Not Working

- Ensure the URL is properly formatted with `?` before parameters
- Use `&` to separate multiple parameters
- Check browser console for the loaded configuration
