# ChatApp Helm Chart

This Helm chart deploys the ChatApp application with all its microservices to Kubernetes.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- PersistentVolume provisioner support in the underlying infrastructure (for production)

## Installation

### Quick Start

Install the chart with the release name `chatapp`:

```bash
helm install chatapp ./helm/chatapp
```

### Install with Custom Values

```bash
helm install chatapp ./helm/chatapp -f ./helm/chatapp/values-dev.yaml
```

### Install in a Different Namespace

```bash
helm install chatapp ./helm/chatapp --create-namespace --namespace my-namespace
```

## Configuration

The following table lists the configurable parameters of the ChatApp chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `chatapp` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |
| `global.imagePullSecrets` | Image pull secrets | `[]` |

### Zookeeper Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `zookeeper.enabled` | Enable Zookeeper | `true` |
| `zookeeper.replicas` | Number of Zookeeper replicas | `1` |
| `zookeeper.image.repository` | Zookeeper image repository | `confluentinc/cp-zookeeper` |
| `zookeeper.image.tag` | Zookeeper image tag | `7.5.0` |
| `zookeeper.persistence.enabled` | Enable persistence | `true` |
| `zookeeper.persistence.storageClass` | Storage class | `""` |
| `zookeeper.persistence.dataSize` | Data volume size | `1Gi` |

### Kafka Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kafka.enabled` | Enable Kafka | `true` |
| `kafka.replicas` | Number of Kafka replicas | `1` |
| `kafka.image.repository` | Kafka image repository | `confluentinc/cp-kafka` |
| `kafka.image.tag` | Kafka image tag | `7.5.0` |
| `kafka.persistence.enabled` | Enable persistence | `true` |
| `kafka.persistence.size` | Data volume size | `2Gi` |

### Python Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pythonService.enabled` | Enable Python service | `true` |
| `pythonService.replicas` | Number of replicas | `2` |
| `pythonService.image.repository` | Image repository | `chatapp-python` |
| `pythonService.image.tag` | Image tag | `latest` |

### Java Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `javaService.enabled` | Enable Java service | `true` |
| `javaService.replicas` | Number of replicas | `2` |
| `javaService.image.repository` | Image repository | `chatapp-java` |
| `javaService.image.tag` | Image tag | `latest` |

### Go Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `goService.enabled` | Enable Go service | `true` |
| `goService.replicas` | Number of replicas | `2` |
| `goService.image.repository` | Image repository | `chatapp-go` |
| `goService.image.tag` | Image tag | `latest` |

### UI Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ui.enabled` | Enable UI | `true` |
| `ui.replicas` | Number of replicas | `2` |
| `ui.service.type` | Service type | `LoadBalancer` |
| `ui.indexHtml` | Custom HTML content | See values.yaml |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.host` | Ingress hostname | `chatapp.local` |
| `ingress.tls.enabled` | Enable TLS | `false` |

## Deployment Examples

### Development Environment

```bash
helm install chatapp ./helm/chatapp -f ./helm/chatapp/values-dev.yaml
```

This will deploy with:
- No persistence (faster startup)
- Single replica for each service
- Lower resource limits
- NodePort service type

### Production Environment

```bash
helm install chatapp ./helm/chatapp -f ./helm/chatapp/values-prod.yaml
```

This will deploy with:
- Persistent storage enabled
- Multiple replicas for high availability
- Higher resource limits
- LoadBalancer service type
- Ingress enabled with TLS

### Custom Configuration

Create your own `my-values.yaml`:

```yaml
pythonService:
  replicas: 5
  image:
    repository: myregistry.io/chatapp-python
    tag: v2.0.0

ingress:
  enabled: true
  host: chat.mycompany.com
```

Deploy with:

```bash
helm install chatapp ./helm/chatapp -f my-values.yaml
```

## Upgrading

### Upgrade with New Values

```bash
helm upgrade chatapp ./helm/chatapp -f ./helm/chatapp/values-prod.yaml
```

### Upgrade Specific Parameters

```bash
helm upgrade chatapp ./helm/chatapp \
  --set pythonService.replicas=5 \
  --set javaService.replicas=5
```

### Rollback

```bash
helm rollback chatapp
```

## Uninstallation

```bash
helm uninstall chatapp
```

To delete the namespace as well:

```bash
kubectl delete namespace chatapp
```

## Building Docker Images

Before deploying, build and tag your Docker images:

```bash
# Build images
docker build -t chatapp-python:latest -f python/Dockerfile .
docker build -t chatapp-java:latest -f java/Dockerfile .
docker build -t chatapp-go:latest -f go/Dockerfile .

# If using a private registry, tag and push
docker tag chatapp-python:latest myregistry.io/chatapp-python:latest
docker push myregistry.io/chatapp-python:latest
```

## Customizing UI Content

### Method 1: Update values.yaml

Edit `values.yaml` and update the `ui.indexHtml` section:

```yaml
ui:
  indexHtml: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>My Custom ChatApp</title>
    </head>
    <body>
      <h1>Welcome to ChatApp</h1>
    </body>
    </html>
```

### Method 2: Use --set-file

```bash
helm install chatapp ./helm/chatapp --set-file ui.indexHtml=./index.html
```

## Monitoring

### Check Deployment Status

```bash
helm status chatapp
```

### View Resources

```bash
kubectl get all -n chatapp
```

### View Logs

```bash
kubectl logs -f deployment/python-service -n chatapp
kubectl logs -f deployment/java-service -n chatapp
kubectl logs -f deployment/go-service -n chatapp
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n chatapp

# Describe pod for events
kubectl describe pod <pod-name> -n chatapp

# Check logs
kubectl logs <pod-name> -n chatapp
```

### Service Connectivity Issues

```bash
# Test internal connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n chatapp -- sh
# Inside the pod:
wget -O- http://kafka:9092
```

### Helm Chart Issues

```bash
# Validate chart
helm lint ./helm/chatapp

# Dry run to see what would be deployed
helm install chatapp ./helm/chatapp --dry-run --debug

# Template to see rendered YAML
helm template chatapp ./helm/chatapp
```

## Advanced Configuration

### Using with ArgoCD

Create an Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: chatapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/chatapp
    targetRevision: HEAD
    path: helm/chatapp
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: chatapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Using with Flux

Create a HelmRelease:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: chatapp
  namespace: chatapp
spec:
  interval: 5m
  chart:
    spec:
      chart: ./helm/chatapp
      sourceRef:
        kind: GitRepository
        name: chatapp
      interval: 1m
  values:
    pythonService:
      replicas: 3
```

## Best Practices

1. **Use environment-specific values files** (`values-dev.yaml`, `values-prod.yaml`)
2. **Version your images** - Don't use `latest` in production
3. **Enable persistence** for Kafka and Zookeeper in production
4. **Configure resource limits** based on actual usage
5. **Use Ingress with TLS** for production deployments
6. **Implement proper monitoring** with Prometheus/Grafana
7. **Regular backups** of persistent data

## License

Copyright © 2025 ChatApp Team
